#!perl -Tw

# This is cut & paste of assert_arrayref.t

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
    assert_arrayref( {} );
};
like( $@, qr/Assertion.*failed/ );

# a ref to a hash with stuff in it is not a listref
my $ref = { foo => 'foo', bar => 'bar' };
eval {
    assert_arrayref( $ref );
};
like( $@, qr/Assertion.*failed/ );

# 3 is not a listref
eval {
    assert_arrayref( 3 );
};
like( $@, qr/Assertion.*failed/ );

# [] is a listref
eval {
    assert_arrayref( [] );
};
is( $@, '' );

# a ref to a list with stuff in it is a listref
my @ary = ('foo', 'bar', 'baaz');
eval {
    assert_arrayref( \@ary );
};
is( $@, '' );

# sub {} is not a listref
eval {
    assert_arrayref( sub {} );
};
like( $@, qr/Assertion.*failed/ );

# Foo->new->isa("ARRAY") returns true, so do we
eval {
    assert_arrayref( Foo->new );
};
is( $@, '' );

done_testing();
exit 0;
