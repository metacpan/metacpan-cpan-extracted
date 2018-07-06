#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use lib '.';
use inc::Module::Install;

all_from('lib/Benchmark/Timer.pm');

auto_set_bugtracker;
githubmeta;

requires(
  'Time::HiRes' => 0,
);

test_requires(
  'Test::More' => 0,
);

check_optional('Statistics::PointEstimation' => 0,
  "Install Statistics::PointEstimation for statistical sampling support\n");

no_index 'file' => 'delta.pl';
no_index 'directory' => 'private-lib';

license 'gpl2';
auto_license(holder => 'David Coppit');

enable_verbose_cpan_testing();

use_standard_tests;

WriteAll();
