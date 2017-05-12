use strict;
use Test::More;
use Acme::MetaSyntactic;

my @themes = grep { !/^(?:any|random)/ } Acme::MetaSyntactic->themes;
my @ams;

for my $theme (@themes) {
    eval "require Acme::MetaSyntactic::$theme;";
    my $ams = "Acme::MetaSyntactic::$theme"->new;
    if ( $ams->isa('Acme::MetaSyntactic::Locale') ) {
        for my $lang ( $ams->languages ) {
            my $a = "Acme::MetaSyntactic::$theme"->new( lang => $lang );
            push @ams, [ $a, sprintf "%s (%s)", $a->theme, $a->lang ];
        }
    }
    elsif ( $ams->isa('Acme::MetaSyntactic::MultiList') ) {
        # check everything at once
        my $a = "Acme::MetaSyntactic::$theme"->new( category => ':all' );
        push @ams, [ $a, sprintf "%s (%s)", $a->theme, $a->category ];
    }
    else {
        push @ams, [ $ams, $ams->theme ];
    }
}

plan tests => scalar @ams;

for my $t (@ams) {
    my ($ams, $theme) = @$t;
    my @items = $ams->name( 0 );
    my @failed;
    my $ok = 0;
    ( length($_) <= 251 && ++$ok ) || push @failed, $_ for @items;
    is( $ok, @items, "All names correct for $theme" );
    diag "Names too long: @failed" if @failed;
}
