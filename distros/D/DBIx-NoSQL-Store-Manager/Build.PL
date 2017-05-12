
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "DBIx::NoSQL as a Moose object store ",
  "dist_author" => [
    "Yanick Champoux <yanick\@babyl.dyndns.org>"
  ],
  "dist_name" => "DBIx-NoSQL-Store-Manager",
  "dist_version" => "0.2.2",
  "license" => "perl",
  "module_name" => "DBIx::NoSQL::Store::Manager",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DBIx::NoSQL" => "0.0020",
    "Method::Signatures" => 0,
    "Module::Pluggable" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::ClassAttribute" => 0,
    "MooseX::Storage" => "0.31",
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
