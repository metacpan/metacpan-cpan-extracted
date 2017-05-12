
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Tiny asynchronous (non-blocking) interface to EC2 using AnyEvent",
  "dist_author" => [
    "Sawyer X <xsawyerx\@cpan.org>"
  ],
  "dist_name" => "AnyEvent-EC2-Tiny",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "AnyEvent::EC2::Tiny",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent::HTTP" => 0,
    "Carp" => 0,
    "HTTP::Tiny" => 0,
    "Moo" => 0,
    "Net::EC2::Tiny" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
