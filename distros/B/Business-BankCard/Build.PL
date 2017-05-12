
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => "0.96"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Utilities for dealing with bank card number (ISO/IEC 7812)",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Business-BankCard",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "Business::BankCard",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "perl" => "5.010000"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
