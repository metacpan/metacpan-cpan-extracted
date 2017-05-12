
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dancer" => "1.3050",
    "Dancer::Test" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Plack::Handler::FCGI" => 0,
    "Plack::Runner" => 0,
    "Template::Declare::Tags" => 0,
    "Test::More" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Template::Declare wrapper for Dancer",
  "dist_author" => [
    "Yanick Champoux"
  ],
  "dist_name" => "Dancer-Template-TemplateDeclare",
  "dist_version" => "0.3.2",
  "license" => "perl",
  "module_name" => "Dancer::Template::TemplateDeclare",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dancer" => "1.3092",
    "Dancer::Config" => 0,
    "Dancer::Template::Abstract" => 0,
    "FindBin" => 0,
    "Template::Declare" => 0,
    "base" => 0,
    "strict" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
