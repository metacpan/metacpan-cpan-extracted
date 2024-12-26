#!perl

use warnings;
use strict;
use 5.010;

use Test::More tests => 7;

use Carp::Assert::More;

sub important_function {
    assert_context_nonvoid( 'void is bad' );

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
like( $@, qr/\QAssertion (void is bad) failed!/ );


# Now we test the assertions with the default message that the function provides.
sub crucial_function {
    assert_context_nonvoid();

    return 2112;
}


# Keep the value returned.
eval {
    my $x = crucial_function();
};
is( $@, '' );


# Keep the value in an array.
eval {
    my @x = crucial_function();
};
is( $@, '' );


# Ignore the value returned.
eval {
    crucial_function();
};
like( $@, qr/\QAssertion (main::crucial_function must not be called in void context) failed!/ );


# Test the default function name through multiple levels in different packages.

package Bingo::Bongo;

use Carp::Assert::More;

sub vital_function {
    assert_context_nonvoid();
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
like( $@, qr/\QAssertion (Bingo::Bongo::vital_function must not be called in void context) failed!/ );

exit 0;
