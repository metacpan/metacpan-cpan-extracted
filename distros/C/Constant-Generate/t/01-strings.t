#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Test::More;

use Constant::Generate [qw(
    FOO
    BAR
    BAZ
)], -type => "str",
    -prefix => "my_",
    -mapname => 'const_str';

ok(my_FOO eq 'FOO', 'prefixed string constants');
is(const_str(my_FOO), 'FOO', 'string constant mapping');

done_testing();