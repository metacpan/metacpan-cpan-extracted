
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Show a spinner in the console on Dancer log messages!',
  'dist_author' => [
    'Sawyer X <xsawyerx@cpan.org>'
  ],
  'dist_name' => 'Dancer-Logger-ConsoleSpinner',
  'dist_version' => '0.02',
  'license' => 'perl',
  'module_name' => 'Dancer::Logger::ConsoleSpinner',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Dancer' => '0',
    'Dancer::Logger::Abstract' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
