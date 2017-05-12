#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use inc::Module::Install;

all_from('lib/CGI/Cache.pm');

auto_set_bugtracker;
githubmeta;

configure_requires(
  # Module::Install::Bugtracker needs this
  'URI::Escape' => 0,
);

requires(
  'File::Path' => 0,
  'Tie::Restore' => 0,
  'File::Spec' => 0,
  'Cache::Cache' => 0,
  'Storable' => 0,
);

test_requires(
  'File::Slurp' => 0,
  'Test::More' => 0,
  'Error' => 0,
);

check_optional('Benchmark::Timer' => '0.7100',
  "Install Benchmark::Timer if you want to run \"make testspeed\"\n");

Add_Test_Target('testspeed', 't/speed.pl');

no_index 'directory' => 'private-lib';

license 'gpl2';
auto_license(holder => 'David Coppit');

enable_verbose_cpan_testing();

use_standard_tests;

WriteAll();
