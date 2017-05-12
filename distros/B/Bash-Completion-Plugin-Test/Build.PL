
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::Exception" => 0,
    "Test::Tester" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Module for testing Bash::Completion plugins",
  "dist_author" => [
    "Rob Hoelz <rob\@hoelz.ro>"
  ],
  "dist_name" => "Bash-Completion-Plugin-Test",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "Bash::Completion::Plugin::Test",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Bash::Completion" => 0,
    "perl" => "v5.8.8"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
