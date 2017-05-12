#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
  module_name => 'Class::Persist',
  license     => 'perl',
  requires    => {
    'perl' => 5.008,
    'Class::Accessor::Chained' => 0,
    'Class::Data::Inheritable' => 0,
    'EO' => 0.93,
    'Data::Structure::Util' => 0,
    'DateTime' => "0.21",
    'DBI' => '0.01',
  },
  build_requires => {
    'DBD::SQLite' => 0,
    'Test::Pod'    => '1.00',
    'Test::Simple' => 0,
    'Test::More'   => 0,
    'File::Find::Rule' => 0,
  },
  create_makefile_pl => 'traditional',
)->create_build_script();
