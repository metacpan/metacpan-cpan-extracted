#!/usr/bin/perl

# t/00signature.t
#  Test that the SIGNATURE matches the distribution
#
# $Id: 00signature.t 10345 2009-12-03 01:51:12Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
  plan skip_all => 'Author tests not required for installation';
}

unless ($ENV{HAS_INTERNET}) {
  plan skip_all => 'Set HAS_INTERNET to enable tests requiring Internet';
}

my %MODULES = (
  'Test::Signature' => 0,
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

plan tests => 1;

signature_ok();
