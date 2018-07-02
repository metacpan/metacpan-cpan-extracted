#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute qw(:core);

subcontract "Foo bared" => sub {
    refute $_[1] != 42, "null test";
}, 42;

ok 1, "intermix 1";
refute 0, "root null test";
ok 3, "intermix 3";

done_testing;
