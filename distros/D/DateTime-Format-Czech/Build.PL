
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
  'build_requires' => {
    'DateTime' => '0',
    'Module::Build' => '0.3601',
    'Test::Most' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Format date and time as usual in Czech.',
  'dist_author' => [
    'Tomáš Znamenáček <zoul@fleuron.cz>'
  ],
  'dist_name' => 'DateTime-Format-Czech',
  'dist_version' => '0.2',
  'license' => 'perl',
  'module_name' => 'DateTime::Format::Czech',
  'recommends' => {},
  'requires' => {
    'Moose' => '0',
    'utf8' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
