#!perl -Tw

package Foo;

sub new { my $class = shift; return bless [ { vh => 5150, r => 2112 }, { foo => 'bar' } ], $class }

package main;

use warnings;
use strict;

use Test::More tests => 8;

use Carp::Assert::More;

local $@;
$@ = '';

# {} is not a arrayref
eval {
    assert_aoh( {} );
};
like( $@, qr/Assertion.*failed/ );

# A hashref is not a arrayref.
my $ref = { foo => 'foo', bar => 'bar' };
eval {
    assert_aoh( $ref );
};
like( $@, qr/Assertion.*failed/ );

# 3 is not a arrayref
eval {
    assert_aoh( 3 );
};
like( $@, qr/Assertion.*failed/ );

# [] is a arrayref
eval {
    assert_aoh( [] );
};
is( $@, '' );

# Arrayref is OK, but it doesn't contain hashrefs.
# a ref to a list with stuff in it is a arrayref
my @ary = ('foo', 'bar', 'baaz');
eval {
    assert_aoh( \@ary );
};
like( $@, qr/Assertion.*failed/ );

# Everything in the arrayref has to be a hash.
@ary = ( { foo => 'bar' }, 'scalar' );
eval {
    assert_aoh( \@ary );
};
like( $@, qr/Assertion.*failed/ );

# sub {} is not a arrayref
eval {
    assert_aoh( sub {} );
};
like( $@, qr/Assertion.*failed/ );

# The return from a constructor is an AOH so it should pass.
eval {
    assert_aoh( Foo->new );
};
is( $@, '' );

exit 0;
