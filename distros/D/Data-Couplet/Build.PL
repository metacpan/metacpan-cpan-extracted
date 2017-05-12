
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dump" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::Moose" => 0,
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Yet another (But Hopefully Better) Key-Value Storage mechanism",
  "dist_author" => [
    "Kent Fredric <kentnl at cpan.org>"
  ],
  "dist_name" => "Data-Couplet",
  "dist_version" => "0.02004314",
  "license" => "perl",
  "module_name" => "Data::Couplet",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Moose" => "0.90",
    "Moose::Role" => 0,
    "MooseX::Clone" => "0.04",
    "MooseX::Types" => "0.19",
    "MooseX::Types::Moose" => "0.19",
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
