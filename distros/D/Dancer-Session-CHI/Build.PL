
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
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "CHI-based session engine for Dancer",
  "dist_author" => [
    "Richard Sim\303\265es <rsimoes AT cpan DOT org>"
  ],
  "dist_name" => "Dancer-Session-CHI",
  "dist_version" => "v0.1.6",
  "license" => "mit",
  "module_name" => "Dancer::Session::CHI",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CHI" => 0,
    "Dancer" => "1.3111",
    "Dancer::Exception" => 0,
    "Scalar::Util" => 0,
    "perl" => "5.008"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
