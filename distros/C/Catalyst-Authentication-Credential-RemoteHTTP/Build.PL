
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Carp" => 0,
    "Catalyst" => 0,
    "Catalyst::Authentication::Store::Minimal" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Test" => 0,
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Server::Simple" => 0,
    "HTTP::Server::Simple::CGI" => 0,
    "IO::Socket::INET" => 0,
    "MIME::Base64" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.94"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Authenticate against remote HTTP server",
  "dist_author" => [
    "Nigel Metheringham <nigelm\@cpan.org>"
  ],
  "dist_name" => "Catalyst-Authentication-Credential-RemoteHTTP",
  "dist_version" => "0.05",
  "license" => "perl",
  "module_name" => "Catalyst::Authentication::Credential::RemoteHTTP",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Catalyst::Exception" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "MooseX::Types::Moose" => 0,
    "base" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.008005",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
