
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "easy database connections for Dancer applications",
  "dist_author" => [
    "celogeek <me\@celogeek.com>"
  ],
  "dist_name" => "Dancer-Plugin-Redis",
  "dist_version" => "0.8",
  "license" => "perl",
  "module_name" => "Dancer::Plugin::Redis",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Dancer::Plugin" => 0,
    "Redis" => "1.955",
    "Try::Tiny" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Dancer" => 0,
    "Dancer::Test" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "JSON" => 0,
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "lib" => 0,
    "perl" => "5.010"
  }
);


my %fallback_build_requires = (
  "Dancer" => 0,
  "Dancer::Test" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON" => 0,
  "Module::Build" => "0.3601",
  "Scalar::Util" => 0,
  "Test::More" => "0.94",
  "lib" => 0,
  "perl" => "5.010"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
