
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Catalyst" => 0,
    "Catalyst::Controller" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "Test::WWW::Mechanize::Catalyst" => 0,
    "parent" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Profile memory usage of requests",
  "dist_author" => [
    "Yanick Champoux <yanick\@babyl.dyndns.org>"
  ],
  "dist_name" => "Catalyst-Plugin-MemoryUsage",
  "dist_version" => "0.4.0",
  "license" => "perl",
  "module_name" => "Catalyst::Plugin::MemoryUsage",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Devel::CheckOS" => 0,
    "List::Util" => 0,
    "MRO::Compat" => 0,
    "Memory::Usage" => 0,
    "Moose::Role" => 0,
    "Number::Bytes::Human" => 0,
    "Text::SimpleTable" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
