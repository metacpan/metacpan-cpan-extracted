#!/usr/bin/perl
use strict;
use warnings;
use Module::Build::Kwalitee;
my $build = Module::Build::Kwalitee->new(
  module_name => 'Class::DBI::PagedSearch',
  license     => 'perl',
  requires    => {
    'perl' => '5.8.1',
    'Class::DBI' => '3.0.14',
    'SQL::Abstract' => 0,
    'Class::DBI::Plugin::Pager' => 0,
  },
  build_requires => {
    'DBD::SQLite'  => 0,
    'Test::More'   => 0,
  },
  create_makefile_pl => 'traditional',
  create_readme => 1,
)->create_build_script();
