
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Scalar::Util' => '1.21',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::NoWarnings' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'java.util.ArrayList for perl',
  'dist_author' => [
    'Alex J. G. Burzyński <ajgb@cpan.org>'
  ],
  'dist_name' => 'Data-ArrayList',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Data::ArrayList',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Data::Clone' => '0.001',
    'Moose' => '1.15'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
