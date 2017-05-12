
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "Test::Most" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "report interesting return values",
  "dist_author" => [
    "Thomas Klausner <domm\@cpan.org>"
  ],
  "dist_name" => "Acme-ReturnValue",
  "dist_version" => "1.001",
  "license" => "perl",
  "module_name" => "Acme::ReturnValue",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Archive::Any" => 0,
    "Data::Dumper" => 0,
    "Encode" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "JSON" => 0,
    "Moose" => 0,
    "MooseX::Getopt" => 0,
    "MooseX::Types::Path::Class" => 0,
    "PPI" => 0,
    "Parse::CPAN::Packages" => 0,
    "Path::Class" => 0,
    "URI::Escape" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/acme_returnvalue_makesite.pl",
    "bin/acme_returnvalue.pl"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
