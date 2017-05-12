#!perl -wT
# $Id: /local/CPAN/Catalyst-Model-NetBlogger/t/pod_coverage.t 1376 2005-11-19T03:45:12.647758Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

eval 'use Pod::Coverage 0.14';
plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;

my $trustme = {
    trustme =>
    [qr/^(stringify|new)$/]
};

all_pod_coverage_ok($trustme);
