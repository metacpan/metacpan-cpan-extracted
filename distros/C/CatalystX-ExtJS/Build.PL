
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
  'dist_abstract' => 'Collection of modules for ExtJS',
  'dist_author' => [
    'Moritz Onken <onken@netcubed.de>'
  ],
  'dist_name' => 'CatalystX-ExtJS',
  'dist_version' => '2.1.3',
  'license' => 'bsd',
  'module_name' => 'CatalystX::ExtJS',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Controller::DBIC::API::RPC' => '0',
    'Catalyst::Plugin::ConfigLoader' => '0',
    'Catalyst::Plugin::Static::Simple' => '0',
    'Catalyst::Plugin::Unicode' => '0',
    'Catalyst::Plugin::Unicode::Encoding' => '0',
    'Catalyst::View::TT::Alloy' => '0',
    'CatalystX::ExtJS::Direct' => '0',
    'CatalystX::ExtJS::REST' => '0',
    'Class::Accessor::Fast' => '0',
    'Config::General' => '0',
    'DBIx::Class::RandomColumns' => '0',
    'DBIx::Class::TimeStamp' => '0',
    'Path::Class' => '0',
    'namespace::autoclean' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
