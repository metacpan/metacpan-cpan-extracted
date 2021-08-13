#!perl -Tw

use warnings;
use strict;
use 5.010;

use Test::More tests => 3;

use Carp::Assert::More;

sub important_function {
    assert_context_nonvoid( 'important_function must not be called in void context' );

    return 2112;
}

local $@;
$@ = '';


# Keep the value returned.
eval {
    my $x = important_function();
};
is( $@, '' );


# Keep the value in an array.
eval {
    my @x = important_function();
};
is( $@, '' );


# Ignore the value returned.
eval {
    important_function();
};
like( $@, qr/\QAssertion (important_function must not be called in void context) failed!/ );


exit 0;
