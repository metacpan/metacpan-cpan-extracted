#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More;

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
