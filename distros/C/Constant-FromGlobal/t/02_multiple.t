#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package Foo;

    use Constant::FromGlobal DEBUG   => {env => 1, bool => 1, default => 1},
                             VERBOSE => {env => 1, bool => 1, default => 0};

    sub foo { DEBUG }

    sub bar { VERBOSE }

    package Bar;

    use Constant::FromGlobal {env => 1}, "DSN",
                             MAX_FOO => {int => 1, default => 3};

    sub foo { DSN }

    sub bar { MAX_FOO }

}

ok( Foo::foo(), "DEBUG enabled" );
ok( !Foo::bar(), "VERBOSE not enabled" );
ok( !defined Bar::foo(), "DSN is undef" );
is( Bar::bar(), 3, "MAX_FOO has correct value" );

done_testing;

# ex: set sw=4 et:

