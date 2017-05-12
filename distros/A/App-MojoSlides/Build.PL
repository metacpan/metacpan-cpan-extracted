#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build::Mojolicious;

my $build = Module::Build::Mojolicious->new(
  module_name        => 'App::MojoSlides',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  configure_requires => { 
    'Module::Build' => 0.36,
    'Module::Build::Mojolicious' => 0,
  },
  requires => {
    'Mojolicious' => '7.15', # Mojo::File
    'Mojolicious::Plugin::InstallablePaths' => 0,
  },
  meta_merge => {
    x_deprecated => 1,
    resources  => {
      repository => "http://github.com/jberger/App-MojoSlides",
      bugtracker => "http://github.com/jberger/App-MojoSlides/issues",
    },
    no_index => {
      file      => [ 'README.pod' ],
    },
  },
);

$build->create_build_script;
