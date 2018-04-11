#!perl

use strict;
use warnings;
use Test::More;

eval "use Module::Runtime;";
$@ and plan skip_all => "Module::Runtime not found. Skipping test.";
Module::Runtime->import("use_module");

eval { use_module("Clone::Choose")->import("no_clone"); };
my $e = $@;

like($e, qr/no_clone is not exportable by Clone::Choose/, "unknown function imported");

done_testing;
