#!perl -Tw

package Foo;

sub new { my $class = shift; return bless [@_], $class; }

package main;

use warnings;
use strict;

use Test::More tests => 7;

use Carp::Assert::More;

local $@;
$@ = '';

# {} is not a listref
eval {
    assert_listref( {} );
};
like( $@, qr/Assertion.*failed/ );

# a ref to a hash with stuff in it is not a listref
my $ref = { foo => 'foo', bar => 'bar' };
eval {
    assert_listref( $ref );
};
like( $@, qr/Assertion.*failed/ );

# 3 is not a listref
eval {
    assert_listref( 3 );
};
like( $@, qr/Assertion.*failed/ );

# [] is a listref
eval {
    assert_listref( [] );
};
is( $@, '' );

# a ref to a list with stuff in it is a listref
my @ary = ('foo', 'bar', 'baaz');
eval {
    assert_listref( \@ary );
};
is( $@, '' );

# sub {} is not a listref
eval {
    assert_listref( sub {} );
};
like( $@, qr/Assertion.*failed/ );

# Foo->new->isa("ARRAY") returns true, so do we
eval {
    assert_listref( Foo->new );
};
is( $@, '' );
