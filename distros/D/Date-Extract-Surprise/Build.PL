
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Data::Dumper' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'extract probable dates from strings *with surprises*',
  'dist_author' => [
    'Stephen R. Scaffidi <sscaffidi@cpan.org>'
  ],
  'dist_name' => 'Date-Extract-Surprise',
  'dist_version' => '0.006',
  'license' => 'perl',
  'module_name' => 'Date::Extract::Surprise',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'DateTime::Format::Flexible' => '0.10',
    'Exporter::Easy' => '0',
    'Scalar::Util' => '0',
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
