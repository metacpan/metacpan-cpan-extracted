use Test::More;
use Acme::MetaSyntactic::any;
use lib 't/lib';
use NoLang;

# "alter" the shuffle method
{
    no warnings;
    my ( $i, $j ) = ( 0, 0 );
    *List::Util::shuffle = sub { sort @_ };    # item selection
    *Acme::MetaSyntactic::any::shuffle =       # theme selection
        sub (@) { my @t = sort @_; push @t, shift @t for 1 .. $j; $j++; @t };
}

# compute the first 6 installed themes
my $meta  = Acme::MetaSyntactic->new();
my $count = my @themes = grep { ! /^any$/ } sort $meta->themes();
my $max = $count >= 6 ? 5 : $count - 1;
@themes = @themes[ 0 .. $max ];

# the test list is computed now because of cache issues
my @tests = map {
    my @items = sort $meta->name( $themes[$_] => 0 );
    [ ( (@items) x ( 1 + int( ( $_ + 1 ) / @items ) ) )[ 0 .. $_ + 1 ] ];
} 0 .. $max;

plan tests => scalar @tests;

for my $test (@tests) {
    my @names = metaany( scalar @$test );
    is_deeply( \@names, $test,
        qq{Got "random" names from a "random" theme (@{[shift @themes]})} );
}

