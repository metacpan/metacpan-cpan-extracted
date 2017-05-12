
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Carp" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "List::Util" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::CheckDeps" => "0.002",
    "Test::More" => "0.94",
    "Test::UseAllModules" => 0,
    "perl" => "5.004"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Executable for App::mio",
  "dist_author" => [
    "DBR <dbr\@cpan.org>"
  ],
  "dist_name" => "App-mio",
  "dist_version" => "0.1.0",
  "license" => "unrestricted",
  "module_name" => "App::mio",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "FindBin" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/mio",
    "bin/mio"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
