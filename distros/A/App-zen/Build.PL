#!/usr/bin/perl
use warnings;
use strict;
use Module::Build;

my $build=Module::Build->new(
  module_name => 'App::zen',
  license => 'perl',
  dist_author => 'Chaoji Li <lichaoji@gmail.com>',
  dist_abstract => 'Zen is a markdown based literate programming tool',
  configure_requires => { 'Module::Build' => 0.42 },
  build_requires => {
    'Test::More' => 0,
  },
  requires => {
    'JSON' => 0,
    'HTTP::Server::Simple' => 0,
    'File::Slurp' => 0,
    'HTTP::Server::Simple::CGI' => 0,
    'File::Basename' => 0,
    'File::Path' => 0,
  },
  create_makefile_pl => 'traditional' # don't require having Module::Build for end-users
)->create_build_script;
