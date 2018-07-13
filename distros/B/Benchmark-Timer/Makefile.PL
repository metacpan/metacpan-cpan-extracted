#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use lib '.';
use inc::Module::Install;

all_from('lib/Benchmark/Timer.pm');

auto_set_bugtracker;
githubmeta;

# Perl 5.6 doesn't work with URI::Escape. We get an error about Exporter not exporting "import"
perl_version '5.008';

configure_requires(
  # Module::Install::Bugtracker needs this
  'URI::Escape' => 0,
);

requires(
  'Time::HiRes' => 0,
);

test_requires(
  'Test::More' => 0,
);

license 'gpl2';

use_standard_tests;

auto_license(holder => 'David Coppit');

check_optional('Statistics::PointEstimation' => 0,
  "Install Statistics::PointEstimation for statistical sampling support\n");

no_index 'file' => 'delta.pl';
no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

realclean_files('inc');

WriteAll;

# ---- Workaround for broken module ----
# https://rt.cpan.org/Ticket/Display.html?id=125772
{
  package Module::Install::StandardTests;

  sub write_standard_test_compile {
      my $self = shift;
      $self->write_test_file('000_standard__compile.t', q/
          BEGIN {
            if ($^O eq 'MSWin32') {
              require Test::More;
              Test::More->import(skip_all =>
                  "Test::Compile doesn't work properly on Windows");
            } else {
              require Test::More;
              Test::More->import();
              eval "use Test::Compile";
              Test::More->builder->BAIL_OUT(
                  "Test::Compile required for testing compilation") if $@;
              all_pm_files_ok();
            }
          }
      /);
  }
}
