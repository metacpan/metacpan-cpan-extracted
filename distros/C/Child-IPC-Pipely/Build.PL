#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Child::IPC::Pipely',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  configure_requires => { 'Module::Build' => 0.38 },
  requires => {
    'Child'      => 0,
    'IO::Pipely' => 0,
  },
  meta_merge => {
    resources => {
      repository => 'https://github.com/jberger/Child-IPC-Pipely',
      bugtracker => 'https://github.com/jberger/Child-IPC-Pipely/issues',
    },
  },
);

$build->create_build_script;
