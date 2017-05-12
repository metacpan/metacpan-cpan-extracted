
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dancer::Test" => 0,
    "File::Find" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "perl" => "v5.10.0"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Dancer plugin to cache response content (and anything else)",
  "dist_author" => [
    "Yanick Champoux <yanick\@cpan.org>"
  ],
  "dist_name" => "Dancer-Plugin-Cache-CHI",
  "dist_version" => "1.4.0",
  "license" => "perl",
  "module_name" => "Dancer::Plugin::Cache::CHI",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CHI" => 0,
    "Carp" => 0,
    "Dancer" => "1.1904",
    "Dancer::Factory::Hook" => 0,
    "Dancer::Hook" => 0,
    "Dancer::Plugin" => 0,
    "Dancer::Response" => 0,
    "Dancer::SharedData" => 0,
    "Moo" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
