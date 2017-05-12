package AI::MicroStructure::test;
use strict;
use Test::More;
use AI::MicroStructure;

plan tests => 1;

ok(1);


__DATA__

# "alter" the shuffle method
{
    no warnings;
    my ( $i, $j ) = ( 0, 0 );
    *List::Util::shuffle = sub { sort @_ };    # item selection
    *AI::MicroStructure::any::shuffle =       # theme selection
        sub (@) { my @t = sort @_; push @t, shift @t for 1 .. $j; $j++; @t };
}

# compute the first 6 installed themes
my $meta   = AI::MicroStructure->new("any");
my @themes = ( grep { ! /^any$/ } sort $meta->structures() )[ 0 .. 5 ];

# the test list is computed now because of cache issues
my @tests
    = map { [ ( sort $meta->name( $themes[$_] => 0 ) )[ 0 .. $_ + 1 ] ] }
0..10;


for my $test (@tests) {
    my @names = microany( scalar @$test );
    is_deeply( \@names, $test,
        qq{Got "random" names from a "random" theme (@{[shift @themes]})} );
}

1;
