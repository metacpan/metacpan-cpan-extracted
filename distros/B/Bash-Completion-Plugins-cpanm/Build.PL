
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Bash completion for cpanm and cpanf',
  'dist_author' => [
    'Moritz Onken'
  ],
  'dist_name' => 'Bash-Completion-Plugins-cpanm',
  'dist_version' => '0.0.2',
  'license' => 'bsd',
  'module_name' => 'Bash::Completion::Plugins::cpanm',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Bash::Completion::Plugin' => '0',
    'Bash::Completion::Utils' => '0',
    'HTTP::Request::Common' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
