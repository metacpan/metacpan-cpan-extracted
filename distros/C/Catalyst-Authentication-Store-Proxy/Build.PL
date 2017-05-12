
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Delegates authentication logic to the user object",
  "dist_author" => [
    "Moritz Onken"
  ],
  "dist_name" => "Catalyst-Authentication-Store-Proxy",
  "dist_version" => "0.0.1",
  "license" => "bsd",
  "module_name" => "Catalyst::Authentication::Store::Proxy",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Catalyst::Utils" => 0,
    "Moose" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
