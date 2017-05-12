
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Digest::MD5" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::Socket" => 0,
    "List::Util" => 0,
    "Module::Build" => "0.3601",
    "Net::SIP" => 0,
    "Net::SIP::Blocker" => 0,
    "Net::SIP::Debug" => 0,
    "Net::SIP::Dropper" => 0,
    "Net::SIP::Dropper::ByField" => 0,
    "Net::SIP::Dropper::ByIPPort" => 0,
    "Net::SIP::Leg" => 0,
    "Net::SIP::NATHelper::Client" => 0,
    "Net::SIP::NATHelper::Local" => 0,
    "Net::SIP::NATHelper::Server" => 0,
    "Net::SIP::ReceiveChain" => 0,
    "Net::SIP::SDP" => 0,
    "Test::More" => 0,
    "base" => 0,
    "fields" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Fusing together AnyEvent and Net::SIP",
  "dist_author" => [
    "Sawyer X <xsawyerx\@cpan.org>"
  ],
  "dist_name" => "AnyEvent-SIP",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "AnyEvent::SIP",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "AnyEvent::AggressiveIdle" => 0,
    "Net::SIP::Dispatcher::Eventloop" => 0,
    "Net::SIP::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
