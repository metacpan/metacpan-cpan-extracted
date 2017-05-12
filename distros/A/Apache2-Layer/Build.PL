
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::Httpd::Apache2' => '0.08',
    'Test::NoWarnings' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Layers for DocumentRoot',
  'dist_author' => [
    'Alex J. G. Burzyński <ajgb@cpan.org>'
  ],
  'dist_name' => 'Apache2-Layer',
  'dist_version' => '1.103360',
  'license' => 'perl',
  'module_name' => 'Apache2::Layer',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'File::Spec' => '3.31',
    'LWP::UserAgent' => '5.835',
    'mod_perl2' => '2.000004'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
