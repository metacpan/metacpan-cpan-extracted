
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.4003",
    "Test::More" => "0.98"
  },
  "configure_requires" => {
    "Module::Build" => "0.4003"
  },
  "dist_abstract" => "A simple plug-in to make forms accessible quickly off the CTX.",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Catalyst-Plugin-Spark-Form",
  "dist_version" => "0.01000002",
  "license" => "perl",
  "module_name" => "Catalyst::Plugin::Spark::Form",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Catalyst::Runtime" => "5.80004",
    "Moose" => "0.92",
    "Moose::Role" => 0,
    "Spark::Form" => "0.2102",
    "namespace::autoclean" => "0.09",
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
