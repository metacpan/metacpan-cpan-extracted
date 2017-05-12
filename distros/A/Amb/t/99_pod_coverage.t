#! /usr/bin/perl
# $Id: 99_pod_coverage.t,v 1.1 2008/07/07 11:22:45 dk Exp $

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD coverage'
     if $@;


plan tests => 1;
pod_coverage_ok( 'Amb' => { trustme => [qr/^(after|fail|dier|patch|find_ctx|caller_op|context_cv)$/x] });
