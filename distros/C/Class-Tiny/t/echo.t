use 5.006;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Echo");

subtest "attribute set as list" => sub {
    my $obj = new_ok( "Echo", [ foo => 42, bar => 23 ] );
    is( $obj->foo, 42, "foo is set" );
    is( $obj->bar, 23, "bar is set" );
    is( $obj->baz, 24, "baz is set" );
};

subtest "destructor" => sub {
    no warnings 'once';
    my @objs = map { new_ok( "Echo", [ foo => 42, bar => 23 ] ) } 1 .. 3;
    is( $Delta::counter, 3, "BUILD incremented counter" );
    @objs = ();
    is( $Delta::counter,   0, "DEMOLISH decremented counter" );
    is( $Delta::exception, 0, "cleanup worked in correct order" );
};

subtest "exceptions" => sub {
    like(
        exception { Echo->new( foo => 0, bar => 23 ) },
        qr/foo must be positive/,
        "BUILD validation throws error",
    );

};

done_testing;
#
# This file is part of Class-Tiny
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
