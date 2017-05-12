#!/usr/bin/perl
use warnings;
use strict;
use Module::Build;

my $build=Module::Build->new
  (
   module_name => 'Algorithm::Step',
   license => 'perl',
   dist_author => 'Chaoji Li <lichaoji@gmail.com>',
   build_requires => {'Test::More'=>0},
   requires => {},
   create_makefile_pl => 'traditional' # don't require having Module::Build for end-users
  )->create_build_script;
