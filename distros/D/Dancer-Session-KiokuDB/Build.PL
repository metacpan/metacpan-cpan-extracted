
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Dancer' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::Fatal' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'KiokuDB Dancer session backend',
  'dist_author' => [
    'Sawyer X <xsawyerx@cpan.org>'
  ],
  'dist_name' => 'Dancer-Session-KiokuDB',
  'dist_version' => '0.05',
  'license' => 'perl',
  'module_name' => 'Dancer::Session::KiokuDB',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Dancer' => '1.3012',
    'Dancer::Config' => '0',
    'Dancer::FileUtils' => '0',
    'Dancer::Logger' => '0',
    'Dancer::ModuleLoader' => '0',
    'Dancer::Session::Abstract' => '0',
    'KiokuDB' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
