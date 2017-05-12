
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::CheckDeps" => "0.002",
    "Test::Deep" => 0,
    "Test::More" => "0.94",
    "Test::NoWarnings" => 0,
    "Test::UseAllModules" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Given a starting date, a number of days and a list of days to be skipped, returns the date X number of days away.",
  "dist_author" => [
    "Alan Young <harleypig\@gmail.com>"
  ],
  "dist_name" => "DateTimeX-Duration-SkipDays",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "DateTimeX::Duration::SkipDays",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "DateTime" => 0,
    "DateTime::Event::Holiday::US" => 0,
    "DateTime::Format::Flexible" => 0,
    "List::MoreUtils" => 0,
    "Try::Tiny" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
