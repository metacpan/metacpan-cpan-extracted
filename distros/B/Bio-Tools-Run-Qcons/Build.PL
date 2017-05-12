
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Copy" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.3601",
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Run Qcons to analyze protein-protein contacts",
  "dist_author" => [
    "Bruno Vecchi <vecchi.b gmail.com>"
  ],
  "dist_name" => "Bio-Tools-Run-Qcons",
  "dist_version" => "0.112881",
  "license" => "perl",
  "module_name" => "Bio::Tools::Run::Qcons",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Capture::Tiny" => 0,
    "File::Temp" => 0,
    "IPC::Cmd" => 0,
    "Mouse" => 0,
    "Mouse::Util::TypeConstraints" => 0,
    "autodie" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
