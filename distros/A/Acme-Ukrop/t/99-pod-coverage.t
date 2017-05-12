#! /usr/bin/perl
# $Id: 99-pod-coverage.t,v 1.1 2008/04/10 13:07:17 dk Exp $

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD coverage'
    if $@;
all_pod_coverage_ok();
