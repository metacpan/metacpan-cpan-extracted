
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
  "dist_abstract" => "like mv, but clever",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "App-mvr",
  "dist_version" => "0.005",
  "license" => "perl",
  "module_name" => "App::mvr",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "POSIX" => 0,
    "Path::Tiny" => "0.034",
    "Pod::Usage" => 0,
    "Try::Tiny" => 0,
    "perl" => "v5.14.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/mvr"
  ],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "IPC::Run3" => 0,
    "Test::Fatal" => 0,
    "Test::Is" => 0,
    "Test::More" => 0,
    "Test::Script::Run" => 0
  }
);


my %fallback_build_requires = (
  "Capture::Tiny" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "IPC::Run3" => 0,
  "Module::Build" => "0.3601",
  "Test::Fatal" => 0,
  "Test::Is" => 0,
  "Test::More" => 0,
  "Test::Script::Run" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
