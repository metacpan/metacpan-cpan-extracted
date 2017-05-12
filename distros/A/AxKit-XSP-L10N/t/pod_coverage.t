#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-L10N/t/pod_coverage.t 1396 2005-03-25T03:58:41.995755Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

eval 'use Pod::Coverage 0.14';
plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;

my $trustme = {
    trustme =>
    [qr/^(translate)$/]
};

all_pod_coverage_ok($trustme);
