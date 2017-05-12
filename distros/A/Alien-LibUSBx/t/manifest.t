#!/usr/bin/perl -w

use strict;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan(skip_all => 'Author tests not required for installation');
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest({exclude => ['/_Inline', '/_alien', '/_share', '/.git']});
