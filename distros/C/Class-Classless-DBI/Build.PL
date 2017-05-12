#!/usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
  module_name => 'Class::Classless::DBI',
  license => 'perl',
  requires => {
    'perl'              => '5.6.1',
    'Class::Classless'  => 0,
  },
  recommends => {
    'SQL::Interpolate'  => '0.33',
  },
  create_makefile_pl => 'traditional',
);
$build->create_build_script;
