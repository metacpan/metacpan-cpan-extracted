#!/usr/bin/env perl

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;

pod_coverage_ok(
    "Crypt::OpenSSL::PKCS12",
    { also_private => ['dl_load_flags'] },
    "Crypt::OpenSSL::PKCS12 is covered"
);
