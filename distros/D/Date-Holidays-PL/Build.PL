
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
  'dist_abstract' => 'Determine holidays for Poland',
  'dist_author' => [
    'Alex J. G. Burzyński <ajgb@cpan.org>'
  ],
  'dist_name' => 'Date-Holidays-PL',
  'dist_version' => '1.110050',
  'license' => 'perl',
  'module_name' => 'Date::Holidays::PL',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Date::Easter' => '0',
    'Date::Holidays::Abstract' => '0',
    'DateTime' => '0',
    'Params::Validate' => '0',
    'Sub::Exporter' => '0',
    'Try::Tiny' => '0',
    'parent' => '0',
    'utf8' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
