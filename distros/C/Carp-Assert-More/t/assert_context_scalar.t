#!perl -Tw

use warnings;
use strict;
use 5.010;

use Test::More tests => 7;

use Carp::Assert::More;


# First we test the assertions with an explicit message passed.

sub important_function {
    assert_context_scalar( 'non-scalar context is bad' );

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
like( $@, qr/\QAssertion (non-scalar context is bad) failed!/ );


# Call in list context.
eval {
    my @x = important_function();
};
like( $@, qr/\QAssertion (non-scalar context is bad) failed!/ );


# Now we test the assertions with the default message that the function provides.
sub crucial_function {
    assert_context_scalar();

    return 2112;
}


local $@;
$@ = '';

# Keep the value returned.
eval {
    my $x = crucial_function();
};
is( $@, '' );


# Ignore the value returned.
eval {
    crucial_function();
};
like( $@, qr/\QAssertion (main::crucial_function must be called in scalar context) failed!/ );


# Call in list context.
eval {
    my @x = crucial_function();
};
like( $@, qr/\QAssertion (main::crucial_function must be called in scalar context) failed!/ );


# Test the default function name through multiple levels in different packages.

package Bingo::Bongo;

use Carp::Assert::More;

sub vital_function {
    assert_context_scalar();
}


package Wango;

sub uninteresting_function {
    Bingo::Bongo::vital_function();
}


package main;

# Ignore the value returned.
eval {
    Wango::uninteresting_function();
};
like( $@, qr/\QAssertion (Bingo::Bongo::vital_function must be called in scalar context) failed!/ );

exit 0;
