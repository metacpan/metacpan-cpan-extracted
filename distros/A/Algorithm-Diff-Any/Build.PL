#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id: Build.PL 10594 2009-12-23 00:25:00Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name           => 'Algorithm::Diff::Any',
  license               => 'perl',
  dist_author           => 'Jonathan Yu <jawnsy@cpan.org>',
  dist_version_from     => 'lib/Algorithm/Diff/Any.pm',
  dynamic_config        => 0,
  create_readme         => 0,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  requires => {
    'perl'              => 5.006,
    'Exporter'          => 5.57, # for: use Exporter 'import'
    'Algorithm::Diff'   => 1.1902, # for OO interface

    # The tests are based on Test::More
    'Test::More'        => 0.62,
  },
  build_requires => {
    # User tests for good functionality
    'Test::NoWarnings'        => 0.084,
  },
  recommends => {
    'Algorithm::Diff::XS'     => 0,
  },
  conflicts => {
  },

  add_to_cleanup => [ 'Algorithm-Diff-Any-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/Algorithm-Diff-Any',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/Algorithm-Diff-Any',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Diff-Any',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

$builder->create_build_script();
