#!/usr/bin/perl -T

# t/01manifest.t
#  Ensures MANIFEST file is up-to-date
#
# $Id: 01manifest.t 10345 2009-12-03 01:51:12Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
  plan skip_all => 'Author tests not required for installation';
}

my %MODULES = (
  'Test::DistManifest'  => 1.002002,
  'Module::Manifest'    => 0.07,
);

while (my ($module, $version) = each %MODULES) {
  eval "use $module $version";
  next unless $@;

  if ($ENV{RELEASE_TESTING}) {
    die 'Could not load release-testing module ' . $module;
  }
  else {
    plan skip_all => $module . ' not available for testing';
  }
}

manifest_ok();
