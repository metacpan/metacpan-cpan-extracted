#!perl

use warnings;
use strict;
use 5.010;

use Test::More tests => 7;

use Carp::Assert::More;

sub important_function {
    assert_context_list( 'must be list' );

    return (2112, 5150, 90125);
}

local $@ = '';


# Keep the value returned.
eval {
    my $x = important_function();
};
like( $@, qr/\QAssertion (must be list) failed!/ );

# Keep the value in an array.
eval {
    my @x = important_function();
};
is( $@, '' );


# Ignore the value returned.
eval {
    important_function();
};
like( $@, qr/\QAssertion (must be list) failed!/ );


# Now we test the assertions with the default message that the function provides.
sub crucial_function {
    assert_context_list();

    return 2112;
}


# Keep the value returned.
eval {
    my $x = crucial_function();
};
like( $@, qr/\QAssertion (main::crucial_function must be called in list context) failed!/ );


# Keep the value in an array.
eval {
    my @x = crucial_function();
};
is( $@, '' );


# Ignore the value returned.
eval {
    crucial_function();
};
like( $@, qr/\QAssertion (main::crucial_function must be called in list context) failed!/ );


# Test the default function name through multiple levels in different packages.

package Bingo::Bongo;

use Carp::Assert::More;

sub vital_function {
    assert_context_list();
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
like( $@, qr/\QAssertion (Bingo::Bongo::vital_function must be called in list context) failed!/ );

exit 0;
