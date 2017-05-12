use strict;
use Test::More;
use Acme::MetaSyntactic;

plan skip_all => "Only useful to the author" unless -d "releases";
my @themes = grep { !/^(?:any)/ } Acme::MetaSyntactic->themes;
my @metas;

for my $theme (@themes) {
    no strict 'refs';
    eval "require Acme::MetaSyntactic::$theme;";
    diag "$theme $@" if $@;
    my %isa = map { $_ => 1 } @{"Acme::MetaSyntactic::$theme\::ISA"};
    if( exists $isa{'Acme::MetaSyntactic::Locale'} ) {
        for my $lang ( "Acme::MetaSyntactic::$theme"->languages() ) {
            push @metas,
                [ "Acme::MetaSyntactic::$theme"->new( lang => $lang ),
                  ", $lang locale" ];
        }
    }
    elsif( exists $isa{'Acme::MetaSyntactic::MultiList'} ) {
        for my $cat ( "Acme::MetaSyntactic::$theme"->categories(), ':all' ) {
            push @metas,
                [ "Acme::MetaSyntactic::$theme"->new( category => $cat ),
                  ", $cat category" ];
        }
    }
    else {
        push @metas, [ "Acme::MetaSyntactic::$theme"->new(), '' ];
    }
}

plan tests => scalar @metas;

for my $test (@metas) {
    my $meta = $test->[0];
    my %items;
    my $items = $meta->name(0);
    $items{$_}++ for $meta->name(0);
    
    is( scalar keys %items, $items, "No duplicates for @{[$meta->theme]}, $items items" . $test->[1] );
    my $dupes = join " ", grep { $items{$_} > 1 } keys %items;
    diag "Duplicates: $dupes" if $dupes;
}

