
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Catalyst' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88',
    'Test::WWW::Mechanize::Catalyst' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Generate tests from HTTP requests',
  'dist_author' => [
    'Moritz Onken <onken@netcubed.de>'
  ],
  'dist_name' => 'CatalystX-Test-Recorder',
  'dist_version' => '1.0.0',
  'license' => 'bsd',
  'module_name' => 'CatalystX::Test::Recorder',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Catalyst::Controller' => '0',
    'Data::Dumper' => '0',
    'List::Util' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Perl::Tidy' => '0',
    'Template::Alloy' => '0',
    'Test::More' => '0.94',
    'Test::WWW::Mechanize::Catalyst' => '0.51',
    'WWW::Mechanize' => '1.60',
    'utf8' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
