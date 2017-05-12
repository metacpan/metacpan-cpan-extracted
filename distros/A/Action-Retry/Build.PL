
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Module to try to perform an action, with various ways of retrying and sleeping between retries.",
  "dist_author" => [
    "Damien \"dams\" Krotkine"
  ],
  "dist_name" => "Action-Retry",
  "dist_version" => "0.24",
  "license" => "perl",
  "module_name" => "Action::Retry",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Math::Fibonacci" => 0,
    "Module::Runtime" => 0,
    "Moo" => 0,
    "Scalar::Util" => 0,
    "Time::HiRes" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.3601",
  "Test::More" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
