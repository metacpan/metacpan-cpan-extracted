
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'DateTime::Format::DateParse' => '0.05',
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Set default Expires header for actions',
  'dist_author' => [
    'Alex J. G. Burzyński <ajgb@cpan.org>'
  ],
  'dist_name' => 'Catalyst-ActionRole-ExpiresHeader',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Catalyst::ActionRole::ExpiresHeader',
  'recommends' => {
    'namespace::autoclean' => '0'
  },
  'recursive_test_files' => 1,
  'requires' => {
    'Catalyst::Controller::ActionRole' => '0.15',
    'HTTP::Date' => '0',
    'Moose' => '0.90'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
