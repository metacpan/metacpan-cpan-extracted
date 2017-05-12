package t::Call::Context::must_be_list;

use strict;
use warnings;

use Test::More;
plan tests => 6;

my $PKG = __PACKAGE__;

use Call::Context;

sub foo {
    Call::Context::must_be_list();
}

sub try {
    return foo();
}

eval { try() };

isa_ok( $@, 'Call::Context::X' );
like( "$@", qr<\Q${PKG}::foo>, 'called function is in message' );
like( "$@", qr<\Q${PKG}::try>, 'calling function is in message' );
like( "$@", qr<void>, 'context is in message (void)' );

scalar eval { try() };

like( "$@", qr<scalar>, 'context is in message (scalar)' );

() = eval { try() };

is( $@, q<>, 'no die() if in list context' );
