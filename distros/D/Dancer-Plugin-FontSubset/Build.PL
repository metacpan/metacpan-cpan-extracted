
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dancer::Plugin::Cache::CHI" => 0,
    "Dancer::Test" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "strict" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Generate font subsets on-the-fly",
  "dist_author" => [
    "Yanick Champoux <yanick\@babyl.dyndns.org>"
  ],
  "dist_name" => "Dancer-Plugin-FontSubset",
  "dist_version" => "0.1.2",
  "license" => "perl",
  "module_name" => "Dancer::Plugin::FontSubset",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dancer" => 0,
    "Dancer::Plugin" => 0,
    "Font::TTF::Font" => 0,
    "Font::TTF::Scripts::Name" => 0,
    "List::AllUtils" => 0,
    "Moo" => 0,
    "MooX::Singleton" => 0,
    "perl" => "v5.12.0",
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
