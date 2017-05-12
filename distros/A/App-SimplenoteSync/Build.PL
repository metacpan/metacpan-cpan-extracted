
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "JSON" => 0,
    "Module::Build" => "0.3601",
    "Path::Class" => 0,
    "Test::More" => 0,
    "Test::utf8" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Synchronise text notes with simplenoteapp.com",
  "dist_author" => [
    "Ioan Rogers <ioanr\@cpan.org>",
    "Fletcher T. Penney <owner\@fletcherpenney.net>"
  ],
  "dist_name" => "App-SimplenoteSync",
  "dist_version" => "0.2.0",
  "license" => "gpl",
  "module_name" => "App::SimplenoteSync",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Config::INI::Reader" => 0,
    "DateTime" => 0,
    "File::BaseDir" => 0,
    "File::Basename" => 0,
    "File::ExtAttr" => 0,
    "Getopt::Long" => 0,
    "Log::Any" => 0,
    "Log::Any::Adapter" => 0,
    "Log::Any::Adapter::Dispatch" => 0,
    "Log::Dispatch" => 0,
    "Log::Dispatch::File" => 0,
    "Log::Dispatch::Screen::Color" => 0,
    "Method::Signatures" => 0,
    "Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Pod::Usage" => 0,
    "Proc::InvokeEditor" => 0,
    "Try::Tiny" => 0,
    "WebService::Simplenote" => "v0.2.0",
    "WebService::Simplenote::Note" => 0,
    "namespace::autoclean" => 0,
    "open" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/simplenotesync"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
