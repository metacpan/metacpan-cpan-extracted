package t::Call::Context::must_be_list;

use strict;
use warnings;

use Test::More;
plan tests => 6;

my $PKG = __PACKAGE__;

use Call::Context;

sub foo {
    Call::Context::must_be_list();
    1;
}

sub try_it {
    return foo();
}

eval { try_it() };

isa_ok( $@, 'Call::Context::X' );
like( "$@", qr<\Q${PKG}::foo>, 'called function is in message' );
like( "$@", qr<\Q${PKG}::try>, 'calling function is in message' );
like( "$@", qr<void>, 'context is in message (void)' );

scalar eval { try_it() };

like( "$@", qr<scalar>, 'context is in message (scalar)' );

scalar eval { () = try_it() };

is( $@, q<>, 'no die() if in list context' );
