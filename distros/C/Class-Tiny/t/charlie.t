use 5.006;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Charlie");

subtest "all attributes set as list" => sub {
    my $obj = new_ok( "Charlie", [ foo => 13, bar => [42] ] );
    is( $obj->foo, 13, "foo is set" );
    is_deeply( $obj->bar, [42], "bar is set" );
};

subtest "custom accessor" => sub {
    my $obj = new_ok( "Charlie", [ foo => 13, bar => [42] ] );
    is_deeply( $obj->bar(qw/1 1 2 3 5/), [qw/1 1 2 3 5/], "bar is set" );
};

subtest "custom accessor with default" => sub {
    my $obj = new_ok( "Charlie", [ foo => 13, bar => [42] ] );
    is( $obj->baz, 23, "custom accessor has default" );
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
