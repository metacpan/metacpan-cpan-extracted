
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Carp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "perl" => "5.004",
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Fetch shipping costs for Canada Post",
  "dist_author" => [
    "Justin Wheeler",
    "Yanick Champoux <yanick\@cpan.org>"
  ],
  "dist_name" => "Business-CanadaPost",
  "dist_version" => "1.06",
  "license" => "gpl",
  "module_name" => "Business::CanadaPost",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "LWP" => 0,
    "strict" => 0,
    "vars" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
