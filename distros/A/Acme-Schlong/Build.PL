
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "List::Util" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::CheckDeps" => "0.002",
    "Test::More" => "0.94",
    "Test::UseAllModules" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "exe-cute-able for Acme::Schlong",
  "dist_author" => [
    "Daniel B. <dbr\@cpan.org>"
  ],
  "dist_name" => "Acme-Schlong",
  "dist_version" => "0.001",
  "license" => "unrestricted",
  "module_name" => "Acme::Schlong",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Acme::Emoticarp" => 0,
    "App::OS::Detect::MachineCores" => 0,
    "Carp" => 0,
    "Config::Any" => 0,
    "Data::Printer" => 0,
    "File::Util" => 0,
    "FindBin" => 0,
    "MetaCPAN::API" => 0,
    "MooseX::AlwaysCoerce" => 0,
    "MooseX::Attribute::ENV" => 0,
    "MooseX::Declare" => 0,
    "MooseX::Getopt::Strict" => 0,
    "MooseX::StrictConstructor" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "MooseX::Types::Perl" => 0,
    "Path::Class" => 0,
    "feature" => 0,
    "perl" => "v5.14.0",
    "strict" => 0,
    "true" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/schlong",
    "bin/schlong"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
