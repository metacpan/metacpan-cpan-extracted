#!perl

use warnings;
use strict;

use Test::More tests => 10;

use Carp::Assert::More;

my %foo = (
    name  => 'Andy Lester',
    phone => '578-3338',
    wango => undef,
);


eval {
    assert_exists( \%foo, 'name' );
};
is( $@, '' );


eval {
    assert_exists( \%foo, 'wango' );
};
is( $@, '' );


eval {
    assert_exists( \%foo, 'Nonexistent' );
};
like( $@, qr/Assert.+failed/ );

# Fails if list of keys to check is undef.
eval {
    assert_exists( \%foo, undef );
};
like( $@, qr/Assert.+failed/ );

# Fails if list of keys to check is not an array.
eval {
    assert_exists( \%foo, {} );
};
like( $@, qr/Assert.+failed/ );

# Fails with empty list of keys to check.
eval {
    assert_exists( \%foo, [] );
};
like( $@, qr/Assert.+failed/ );

eval {
    assert_exists( \%foo, [qw( name )] );
};
is( $@, '' );

eval {
    assert_exists( \%foo, [qw( name social-security-number )] );
};
like( $@, qr/Assertion.+failed/ );

eval {
    assert_exists( \%foo, [qw( name phone )] );
};
is( $@, '' );


eval {
    assert_exists( \%foo, ['name','Nonexistent'] );
};
like( $@, qr/Assert.+failed/ );
