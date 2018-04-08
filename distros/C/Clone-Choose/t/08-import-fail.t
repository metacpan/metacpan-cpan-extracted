#!perl

use strict;
use warnings;
use Test::More;
use Module::Runtime qw(use_module);

eval "use Clone;";
$@ and plan skip_all => "No Clone found. Can't prove load successfull with :Clone.";

eval { use_module("Clone::Choose")->import("no_clone"); };
my $e = $@;

like($e, qr/no_clone is not exportable by Clone::Choose/, "unknown function imported");

done_testing;
