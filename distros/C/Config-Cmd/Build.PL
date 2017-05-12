
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "Try::Tiny" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Command line to config file two way interface",
  "dist_author" => [
    "Heikki Lehvaslaiho <heikki.lehvaslaiho\@gmail.com>"
  ],
  "dist_name" => "Config-Cmd",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Config::Cmd",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Getopt::Long" => 0,
    "Mo" => 0,
    "Modern::Perl" => 0,
    "YAML" => 0,
    "constant" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/configcmd"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
