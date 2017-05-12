
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Bash::Completion::Plugin::Test" => 0,
    "Module::Build" => "0.3601",
    "Module::Find" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Bash::Completion support for Dist::Zilla",
  "dist_author" => [
    "Rob Hoelz <rob\@hoelz.ro>"
  ],
  "dist_name" => "Bash-Completion-Plugins-dzil",
  "dist_version" => "0.02",
  "license" => "perl",
  "module_name" => "Bash::Completion::Plugins::dzil",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Bash::Completion::Plugins::App::Cmd" => 0,
    "Dist::Zilla" => 0,
    "perl" => "v5.10.0"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
