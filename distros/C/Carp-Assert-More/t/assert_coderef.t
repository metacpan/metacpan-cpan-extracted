#!perl -Tw

package Foo;

sub new { my $class = shift; return bless sub {}, $class; }

package main;

use warnings;
use strict;

use Test::More tests => 7;

use Carp::Assert::More;

local $@;
$@ = '';

# {} is not a coderef
eval {
    assert_coderef( {} );
};
like( $@, qr/Assertion.*failed/ );

# a ref to a hash with stuff in it is not a coderef
my $ref = { foo => 'foo', bar => 'bar' };
eval {
    assert_coderef( $ref );
};
like( $@, qr/Assertion.*failed/ );

# 3 is not a coderef
eval {
    assert_coderef( 3 );
};
like( $@, qr/Assertion.*failed/ );

# [] is not a coderef
eval {
    assert_coderef( [] );
};
like( $@, qr/Assertion.*failed/ );

# a ref to a list with stuff in it is not a coderef
my @ary = ('foo', 'bar', 'baaz');
eval {
    assert_coderef( \@ary );
};
like( $@, qr/Assertion.*failed/ );

# sub {} is a coderef
eval {
    assert_coderef( sub {} );
};
is( $@, '' );

# Foo->new->isa("CODE") returns true, so do we
eval {
    assert_coderef( Foo->new );
};
is( $@, '' );
