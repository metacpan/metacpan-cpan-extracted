package t::Call::Context::must_not_be_scalar;

use strict;
use warnings;

use Test::More;
plan tests => 6;

my $PKG = __PACKAGE__;

use Call::Context;

sub foo {
    Call::Context::must_not_be_scalar();
    1;
}

sub try {
    return foo();
}

scalar eval { try() };

isa_ok( $@, 'Call::Context::X' );
like( "$@", qr<\Q${PKG}::foo>, 'called function is in message' );
like( "$@", qr<\Q${PKG}::try>, 'calling function is in message' );
like( "$@", qr<scalar>, 'context is in message' );

eval { try() };

is( $@, q<>, 'no die() if in void context' );

() = eval { try() };

is( $@, q<>, 'no die() if in list context' );
