#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run author tests'
    unless $ENV{RELEASE_TESTING};

eval 'use Test::Pod::Coverage 1.08';
plan skip_all => 'Test::Pod::Coverage 1.08 required' if $@;

# Every public sub must be documented. Private helpers (leading
# underscore), the XS bootstrap, and the all-caps protocol constants in
# the TCP module are exempt - they are implementation detail, not API.
my $private = qr/^(?:_|[A-Z][A-Z0-9_]*$)/;

pod_coverage_ok(
    'ClickHouse::Encoder',
    { also_private => [$private],
      coverage_class => 'Pod::Coverage::CountParents' },
    'ClickHouse::Encoder public API is fully documented',
);

pod_coverage_ok(
    'ClickHouse::Encoder::TCP',
    { also_private => [$private],
      coverage_class => 'Pod::Coverage::CountParents' },
    'ClickHouse::Encoder::TCP public API is fully documented',
);

done_testing();
