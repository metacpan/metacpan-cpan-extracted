#!/usr/bin/perl

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;

pod_coverage_ok(
    "Audio::FLAC::Header",
    { also_private => ['dl_load_flags'] },
    "Audio::FLAC::Header is covered"
);
