
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Template::Tiny backend to Dancer',
  'dist_author' => [
    'Sawyer X <xsawyerx@cpan.org>'
  ],
  'dist_name' => 'Dancer-Template-Tiny',
  'dist_version' => '0.03',
  'license' => 'perl',
  'module_name' => 'Dancer::Template::Tiny',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Dancer::FileUtils' => '0',
    'Dancer::Template::Abstract' => '0',
    'Template::Tiny' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
