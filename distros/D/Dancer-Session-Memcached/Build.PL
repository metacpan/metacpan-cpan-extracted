
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Memcached-based session backend for Dancer",
  "dist_author" => [
    "Alexis Sukrieh <surkia\@sukria.net>"
  ],
  "dist_name" => "Dancer-Session-Memcached",
  "dist_version" => "0.202",
  "license" => "perl",
  "module_name" => "Dancer::Session::Memcached",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Cache::Memcached" => 0,
    "Carp" => 0,
    "Dancer::Config" => 0,
    "Dancer::ModuleLoader" => 0,
    "Dancer::Session::Abstract" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
