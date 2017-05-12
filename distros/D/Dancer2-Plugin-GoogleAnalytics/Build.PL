
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
  "dist_abstract" => "A Dancer2 plugin to easily add Google Analytics code.",
  "dist_author" => [
    "Cesare Gargano <garcer\@cpan.org>"
  ],
  "dist_name" => "Dancer2-Plugin-GoogleAnalytics",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Dancer2::Plugin::GoogleAnalytics",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dancer2" => 0,
    "Dancer2::Core::Hook" => 0,
    "Dancer2::Plugin" => 0,
    "Moo::Role" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "List::Util" => 0,
    "Test::More" => 0,
    "perl" => "5.006"
  }
);


my %fallback_build_requires = (
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "Module::Build" => "0.3601",
  "Test::More" => 0,
  "perl" => "5.006"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
