#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use Module::Build;

use warnings;
use strict;

require 5.010001 ;

my @version_info = @ARGV ? ( dist_version => $ARGV[0] ) : ();

my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

my $build = Module::Build->new(
    module_name => 'Config::Model::Systemd',
    @version_info,
    license       => 'lgpl',
    appli_files   => \%appli_files,
    dist_abstract => 'configuration editor for systemd',
    dist_author   => 'Dominique Dumont (ddumont at cpan dot org)',

  'build_requires' => {
    'Config::Model::Tester' => '2.054',
    'Module::Build' => '0.34',
    'Test::File::Contents' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.34'
  },
  'recommends' => {
    'App::Cme' => '0',
    'Config::Model::TkUI' => '0'
  },
  'requires' => {
    'Config::Model' => '2.111',
    'Config::Model::Backend::Any' => '0',
    'Config::Model::Backend::IniFile' => '0',
    'Log::Log4perl' => '0',
    'Mouse' => '0',
    'Mouse::Role' => '0',
    'Path::Tiny' => '0.086',
    'perl' => '5.010'
  },

    add_to_cleanup => [ qw/wr_root/ ],
);

$build->add_build_element('pl');
$build->add_build_element('appli');

$build->create_build_script;
