#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use Alien::DBD::SQLite::BundledExtensions;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Alien::DBD::SQLite::BundledExtensions',

  license => 'artistic_2', # TODO this might need to change based on the license of the extensions I'm bundling with this.  Do more research.
  alien_repository => {
    protocol => 'local',
    location => 'source/',
    pattern  => qr{^sqlite-src-([0-9\.]+)\.zip$},
  },

  configure_requires => {
    'Alien::Base::ModuleBuild' => '0.005',
    'Module::Build' => '0.28',
    'DBD::SQLite' => 0,
    'Archive::Zip' => 0,
  },
  requires => {
    'Alien::Base' => '0.005',
    'DBD::SQLite' => 0,
  },
  
  alien_build_commands => Alien::DBD::SQLite::BundledExtensions::get_build_commands(),
  alien_install_commands => Alien::DBD::SQLite::BundledExtensions::get_install_commands(),
);

$builder->create_build_script;

