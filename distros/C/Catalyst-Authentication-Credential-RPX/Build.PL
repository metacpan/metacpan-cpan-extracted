
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::Fatal" => 0,
    "Test::MockObject" => 0,
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Use JanRain's RPX service for Credentials",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Catalyst-Authentication-Credential-RPX",
  "dist_version" => "0.10060100",
  "license" => "bsd",
  "module_name" => "Catalyst::Authentication::Credential::RPX",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Moose" => 0,
    "MooseX::Has::Sugar" => "0.0300",
    "MooseX::Types::Moose" => 0,
    "Net::API::RPX" => "0.04",
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
