#!perl -Tw

use warnings;
use strict;
use 5.010;

use Test::More tests => 3;

use Carp::Assert::More;

sub important_function {
    assert_context_scalar( 'important_function must be called in scalar context' );

    return 2112;
}


local $@;
$@ = '';

# Keep the value returned.
eval {
    my $x = important_function();
};
is( $@, '' );


# Ignore the value returned.
eval {
    important_function();
};
like( $@, qr/\QAssertion (important_function must be called in scalar context) failed!/ );


# Call in list context.
eval {
    my @x = important_function();
};
like( $@, qr/\QAssertion (important_function must be called in scalar context) failed!/ );


exit 0;
