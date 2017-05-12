
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Catalyst' => '0',
    'Catalyst::Model::DBIC::Schema' => '0',
    'Catalyst::Request::REST::ForBrowsers' => '0',
    'Catalyst::View::JSON' => '0',
    'CatalystX::Controller::ExtJS::Direct' => '0',
    'CatalystX::Controller::ExtJS::REST' => '0',
    'DBIx::Class' => '0',
    'DBIx::Class::Schema' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'HTTP::Request::Common' => '0',
    'JSON' => '0',
    'Module::Build' => '0.3601',
    'Path::Class::File' => '0',
    'Spreadsheet::ParseExcel' => '0',
    'Test::More' => '0.88',
    'Test::WWW::Mechanize::Catalyst' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Serialize to Excel spreadsheets',
  'dist_author' => [
    'Moritz Onken'
  ],
  'dist_name' => 'CatalystX-Controller-ExtJS-REST-SimpleExcel',
  'dist_version' => '0.1.1',
  'license' => 'bsd',
  'module_name' => 'CatalystX::Controller::ExtJS::REST::SimpleExcel',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Catalyst::Action::Serialize::SimpleExcel' => '0.015',
    'CatalystX::ExtJS' => '2.0.0',
    'JSON::XS' => '0',
    'Moose' => '0',
    'Moose::Meta::Role::Application::ToClass' => '0',
    'Moose::Role' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
