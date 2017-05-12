
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Cache::Ref::Null" => 0,
    "Modern::Perl" => 0,
    "Module::Build" => "0.3601",
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Time::HiRes" => 0,
    "YAML::Any" => 0,
    "autodie" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Digest your protein substrates with customizable specificity",
  "dist_author" => [
    "Bruno Vecchi <vecchi.b gmail.com>"
  ],
  "dist_name" => "Bio-Protease",
  "dist_version" => "1.112980",
  "license" => "perl",
  "module_name" => "Bio::Protease",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Cache::Ref::LRU" => 0,
    "Carp" => 0,
    "Moose" => "1.23",
    "Moose::Role" => 0,
    "MooseX::ClassAttribute" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "namespace::autoclean" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
