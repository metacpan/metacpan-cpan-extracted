
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
  "dist_abstract" => "Power sets of hashes",
  "dist_author" => [
    "Sawyer X <xsawyerx\@cpan.org>",
    "Mirela Iclodean <imirela\@cpan.org>"
  ],
  "dist_name" => "Data-PowerSet-Hash",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "Data::PowerSet::Hash",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::PowerSet" => 0,
    "Exporter" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Deep::NoTest" => 0,
    "Test::More" => 0
  }
);


my %fallback_build_requires = (
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.3601",
  "Test::Deep::NoTest" => 0,
  "Test::More" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
