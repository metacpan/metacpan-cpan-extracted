#!/usr/bin/perl
# $Id: 02_pod_coverage.t 17 2009-01-24 10:38:38Z rjray $

use Test::More;

our @MODULES = qw(App::Changelog2x);

eval "use Test::Pod::Coverage 1.00";

plan skip_all =>
    "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
plan tests => scalar(@MODULES);

pod_coverage_ok($_) for (@MODULES);

exit;
