
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
  'dist_abstract' => 'This is a plugin to access information about RT tickets on IRC',
  'dist_author' => [
    'Damien "dams" Krotkine'
  ],
  'dist_name' => 'Bot-BasicBot-Pluggable-Module-RT',
  'dist_version' => '0.20',
  'license' => 'perl',
  'module_name' => 'Bot::BasicBot::Pluggable::Module::RT',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Bot::BasicBot::Pluggable::Module' => '0',
    'RT::Client::REST' => '0',
    'RT::Client::REST::Ticket' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
