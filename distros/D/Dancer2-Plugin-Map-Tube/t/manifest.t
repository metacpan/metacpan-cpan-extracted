#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan skip_all => 'AUTHOR_TESTING required for this test' unless $ENV{AUTHOR_TESTING};

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest({filter => [qr/\.git/]});
