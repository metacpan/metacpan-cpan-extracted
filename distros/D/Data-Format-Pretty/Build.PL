
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Format::Pretty::JSON" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.96"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Pretty-print data structure",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Data-Format-Pretty",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "Data::Format::Pretty",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Format::Pretty::Console" => 0,
    "Data::Format::Pretty::HTML" => "0.06",
    "perl" => "5.010001"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
