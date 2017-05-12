
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Sub::Override" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Collect information from multiple sources",
  "dist_author" => [
    "Sawyer X <xsawyerx\@cpan.org>"
  ],
  "dist_name" => "Data-Collector",
  "dist_version" => "0.15",
  "license" => "perl",
  "module_name" => "Data::Collector",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Class::Load" => 0,
    "Data::Dumper" => 0,
    "File::HomeDir" => 0,
    "File::Spec" => 0,
    "IPC::System::Simple" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Module::Pluggable::Object" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Getopt::Dashes" => 0,
    "MooseX::SimpleConfig" => 0,
    "MooseX::Types::Path::Class" => 0,
    "MooseX::Types::Set::Object" => 0,
    "Net::OpenSSH" => 0,
    "Set::Object" => 0,
    "YAML" => 0,
    "indirect" => 0,
    "namespace::autoclean" => 0,
    "strictures" => 1
  },
  "script_files" => [
    "bin/data-collector"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
