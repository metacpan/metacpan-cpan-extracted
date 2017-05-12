
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "App::Cmd::Tester" => 0,
    "App::Scaffolder" => 0,
    "Carp" => 0,
    "Directory::Scratch" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::Class" => 0,
    "Test::File" => 0,
    "Test::File::ShareDir" => 0,
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "App::Scaffolder extension to scaffold HTML files",
  "dist_author" => [
    "Manfred Stock <mstock\@cpan.org>"
  ],
  "dist_name" => "App-Scaffolder-HTML",
  "dist_version" => "0.001000",
  "license" => "perl",
  "module_name" => "App::Scaffolder::HTML",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "App::Scaffolder" => "0.002000",
    "App::Scaffolder::Command" => 0,
    "MRO::Compat" => 0,
    "Path::Class::Dir" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
