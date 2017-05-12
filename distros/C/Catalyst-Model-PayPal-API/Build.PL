
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A Catalyst Model for PayPal via Business::PayPal::API",
  "dist_author" => [
    "Dean Hamstead <dean\@fragfest.com.au>"
  ],
  "dist_name" => "Catalyst-Model-PayPal-API",
  "dist_version" => "0.32",
  "license" => "perl",
  "module_name" => "Catalyst::Model::PayPal::API",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Business::PayPal::API" => 0,
    "Catalyst::Model" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
