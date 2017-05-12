
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "DBIx::Class::Schema" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::Memory::Cycle" => 0,
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Represent a graph in a relational database using DBIC",
  "dist_author" => [
    "Moritz Onken <onken\@netcubed.de>"
  ],
  "dist_name" => "DBIx-Class-Graph",
  "dist_version" => "1.05",
  "license" => "bsd",
  "module_name" => "DBIx::Class::Graph",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Class::C3" => 0,
    "DBIx::Class" => 0,
    "DBIx::Class::ResultSet" => 0,
    "Graph" => "0.94",
    "List::MoreUtils" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Scalar::Util" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
