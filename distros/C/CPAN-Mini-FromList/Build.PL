
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "create a minimal CPAN mirror from a list of modules you specify",
  "dist_author" => [
    "Thomas Klausner <domm\@cpan.org>"
  ],
  "dist_name" => "CPAN-Mini-FromList",
  "dist_version" => "0.05",
  "license" => "perl",
  "module_name" => "CPAN::Mini::FromList",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CPAN::Mini" => 0,
    "Data::Dumper" => 0,
    "File::Find::Rule" => 0,
    "File::Spec::Functions" => 0,
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/minicpan-fromlist"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
