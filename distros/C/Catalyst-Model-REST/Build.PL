
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Serializer" => 0,
    "Data::Serializer::JSON" => 0,
    "Data::Serializer::XML::Simple" => 0,
    "Data::Serializer::YAML" => 0,
    "JSON" => "2.00",
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "XML::Simple" => 0,
    "YAML" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "REST model class for Catalyst",
  "dist_author" => [
    "Kaare Rasmussen <kaare at cpan dot net>"
  ],
  "dist_name" => "Catalyst-Model-REST",
  "dist_version" => "0.27",
  "license" => "perl",
  "module_name" => "Catalyst::Model::REST",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Catalyst::Model" => 0,
    "Moose" => 0,
    "Role::REST::Client" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
