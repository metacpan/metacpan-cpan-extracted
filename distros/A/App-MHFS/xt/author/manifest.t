#!perl
use 5.014;
use strict;
use warnings;
use Test2::V0;

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
