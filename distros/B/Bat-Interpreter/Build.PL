
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.015.
use strict;
use warnings;

use Module::Build 0.28;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.28"
  },
  "configure_requires" => {
    "Module::Build" => "0.28"
  },
  "dist_abstract" => "Pure perl interpreter for a small subset of bat/cmd files",
  "dist_author" => [
    "Pablo Rodr\x{ed}guez Gonz\x{e1}lez <pablo.rodriguez.gonzalez\@gmail.com>"
  ],
  "dist_name" => "Bat-Interpreter",
  "dist_version" => "0.025",
  "license" => "mit",
  "module_name" => "Bat::Interpreter",
  "recursive_test_files" => 1,
  "requires" => {
    "App::BatParser" => "0.011",
    "Carp" => 0,
    "Data::Dumper" => 0,
    "File::Glob" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "Path::Tiny" => 0,
    "Types::Standard" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.014",
    "utf8" => 0
  },
  "test_requires" => {
    "English" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "strict" => 0,
    "warnings" => 0
  }
);


my %fallback_build_requires = (
  "English" => 0,
  "Module::Build" => "0.28",
  "Test::Exception" => 0,
  "Test::More" => 0,
  "Test::Most" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
