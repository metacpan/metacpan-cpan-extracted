#!perl -Tw

package Foo;

sub new { my $class = shift; return bless {@_}, $class; }

package main;

use warnings;
use strict;

use Test::More tests => 6;

use Carp::Assert::More;

local $@;
$@ = '';

# {} is a hashref
eval {
    assert_hashref( {} );
};
is( $@, '' );

# a ref to a hash with stuff in it is a hashref
my %hash = ( foo => 'foo', bar => 'bar' );
eval {
    assert_hashref( \%hash );
};
is( $@, '' );

# 3 is not a hashref
eval {
    assert_hashref( 3 );
};
like( $@, qr/Assertion.*failed/ );

# [] is not a hashref
eval {
    assert_hashref( [] );
};
like( $@, qr/Assertion.*failed/ );

# sub {} is not a hashref
eval {
    assert_hashref( sub {} );
};
like( $@, qr/Assertion.*failed/ );

# Foo->new->isa("HASH") returns true, so do we
eval {
    assert_hashref( Foo->new );
};
is( $@, '' );

