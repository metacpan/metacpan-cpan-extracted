
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "App::Cmd::Tester" => 0,
    "Directory::Scratch" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::File" => 0,
    "Test::File::ShareDir" => 0,
    "Test::More" => "0.88",
    "parent" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Application for scaffolding using templates",
  "dist_author" => [
    "Manfred Stock <mstock\@cpan.org>"
  ],
  "dist_name" => "App-Scaffolder",
  "dist_version" => "0.002000",
  "license" => "perl",
  "module_name" => "App::Scaffolder",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "App::Cmd::Setup" => 0,
    "Carp" => 0,
    "Config" => 0,
    "File::HomeDir" => "0.93",
    "File::ShareDir" => 0,
    "File::Spec" => 0,
    "MRO::Compat" => 0,
    "Path::Class" => "0.17",
    "Path::Class::Dir" => 0,
    "Path::Class::File" => 0,
    "Scalar::Util" => 0,
    "Template" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/scaffolder"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
