
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Command Line Input/Output with sockets and HTTP",
  "dist_author" => [
    "Alex J. G. Burzy\305\204ski <ajgb\@cpan.org>"
  ],
  "dist_name" => "Clio",
  "dist_version" => "0.02",
  "license" => "perl",
  "module_name" => "Clio",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "AnyEvent::Handle" => 0,
    "AnyEvent::Run" => 0,
    "AnyEvent::Socket" => 0,
    "Carp" => 0,
    "Class::Load" => 0,
    "Config::Any" => 0,
    "Config::General" => 0,
    "Data::UUID" => 0,
    "Log::Log4perl" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "Net::Server::Daemonize" => 0,
    "Plack::Request" => 0,
    "Plack::Util" => 0,
    "Protocol::WebSocket::Frame" => 0,
    "Protocol::WebSocket::Handshake::Server" => 0,
    "Role::Tiny" => 0,
    "Scalar::Util" => 0,
    "Twiggy::Server" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/clio"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
