
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Simple workflow manager",
  "dist_author" => [
    "Heikki Lehvaslaiho, KAUST (King Abdullah University of Science and Technology)."
  ],
  "dist_name" => "App-Pipeline-Simple",
  "dist_version" => "0.9.1",
  "license" => "perl",
  "module_name" => "App::Pipeline::Simple",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "Getopt::Long" => 0,
    "GraphViz" => 0,
    "Log::Log4perl" => 0,
    "YAML::Syck" => 0,
    "autodie" => 0,
    "constant" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/spipe"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
