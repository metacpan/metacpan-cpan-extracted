
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
  'dist_abstract' => 'CPAN GUI in Gtk2',
  'dist_author' => [
    'Sawyer X <xsawyerx@cpan.org>'
  ],
  'dist_name' => 'App-cpang',
  'dist_version' => '0.03',
  'license' => 'perl',
  'module_name' => 'App::cpang',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Glib' => '0',
    'Gnome2::Vte' => '0',
    'Gtk2' => '0'
  },
  'script_files' => [
    'bin/cpang'
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
