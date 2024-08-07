
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.031.
use strict;
use warnings;

use Module::Build 0.30;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.30",
    "Test::More" => "0.4234"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => 0,
    "Module::Build" => "0.30"
  },
  "dist_abstract" => "Spanish holidays",
  "dist_author" => [
    "Jonas B. <jonasbn\@cpan.org>"
  ],
  "dist_name" => "Date-Holidays-ES",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Date::Holidays::ES",
  "recursive_test_files" => 1,
  "requires" => {
    "Date::Easter" => 0,
    "Date::Holidays::Super" => 0,
    "DateTime" => 0,
    "Time::JulianDay" => 0
  },
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.4234"
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.30",
  "Test::More" => "0.4234"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
