#
# This file is part of Config-Model-Backend-Yaml
#
# This software is Copyright (c) 2018 by Dominique Dumont.
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

my $build = Module::Build->new(
    module_name => 'Config::Model::Backend::Yaml',
    @version_info,
    license       => 'lgpl',
    dist_abstract => 'Config::Model plugin to read and write YAML files',
    dist_author   => 'Dominique Dumont (ddumont at cpan dot org)',

  'build_requires' => {
    'Config::Model::Tester' => '4.001',
    'Config::Model::Tester::Setup' => '0',
    'ExtUtils::testlib' => '0',
    'Module::Build' => '0.34',
    'Path::Tiny' => '0',
    'Test::Memory::Cycle' => '0',
    'Test::More' => '0',
    'lib' => '0',
    'utf8' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.34'
  },
  'requires' => {
    'Carp' => '0',
    'Config::Model' => '2.131',
    'Config::Model::Backend::Any' => '0',
    'Config::Model::Exception' => '0',
    'File::Path' => '0',
    'Log::Log4perl' => '0',
    'YAML::XS' => '0.69',
    'base' => '0',
    'boolean' => '0',
    'parent' => '0',
    'perl' => 'v5.12.0',
    'strict' => '0',
    'warnings' => '0'
  },

    add_to_cleanup => [ qw/wr_root/ ],
);

$build->add_build_element('pl');

$build->create_build_script;
