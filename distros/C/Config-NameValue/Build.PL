
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::CheckDeps" => 0,
    "Test::File" => 0,
    "Test::File::Contents" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Test::NoWarnings" => 0,
    "Test::Requires" => 0,
    "Test::UseAllModules" => 0,
    "perl" => "5.006"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Round trip simple name/value config file handling.",
  "dist_author" => [
    "Alan Young <harleypig\@gmail.com>"
  ],
  "dist_name" => "Config-NameValue",
  "dist_version" => "1.03",
  "license" => "perl",
  "module_name" => "Config::NameValue",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "File::Slurp" => 0,
    "IO::Handle" => 0,
    "POSIX" => 0,
    "Scalar::Util" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
