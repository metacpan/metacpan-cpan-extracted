
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Copy::Recursive" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Path::Class" => 0,
    "Test::File" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "Test::Trap" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Archive Devel::Cover reports",
  "dist_author" => [
    "Thomas Klausner <domm\@cpan.org>"
  ],
  "dist_name" => "App-ArchiveDevelCover",
  "dist_version" => "1.002",
  "license" => "perl",
  "module_name" => "App::ArchiveDevelCover",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DateTime" => 0,
    "File::Copy" => 0,
    "HTML::TableExtract" => 0,
    "Moose" => 0,
    "MooseX::Getopt" => 0,
    "MooseX::Types::Path::Class" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/archive_devel_cover.pl"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
