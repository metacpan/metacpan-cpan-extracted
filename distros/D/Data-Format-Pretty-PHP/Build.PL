
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
  "dist_abstract" => "Pretty-print data structure as PHP code",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Data-Format-Pretty-PHP",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Data::Format::Pretty::PHP",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Dump::PHP" => 0,
    "perl" => "5.010000"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
