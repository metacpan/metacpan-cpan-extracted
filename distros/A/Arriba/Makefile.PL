
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.17;



my %WriteMakefileArgs = (
  "ABSTRACT" => "PSGI web server with SPDY support",
  "AUTHOR" => "Michal Wojciechowski <odyniec\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "Arriba",
  "EXE_FILES" => [
    "bin/arriba"
  ],
  "LICENSE" => "perl",
  "NAME" => "Arriba",
  "PREREQ_PM" => {
    "Data::Dump" => 0,
    "HTTP::Date" => 0,
    "HTTP::Parser::XS" => 0,
    "HTTP::Status" => 0,
    "IO::Socket" => 0,
    "IO::Socket::SSL" => 0,
    "Net::SPDY::Session" => 0,
    "Net::Server::PreFork" => 0,
    "Net::Server::SIG" => 0,
    "Plack::Runner" => 0,
    "Plack::TempBuffer" => 0,
    "Plack::Util" => 0,
    "Socket" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "HTTP::Request::Common" => 0,
    "HTTP::Tiny::SPDY" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "List::Util" => 0,
    "Plack::LWPish" => 0,
    "Plack::Test::Suite" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.020",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dump" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "HTTP::Date" => 0,
  "HTTP::Parser::XS" => 0,
  "HTTP::Request::Common" => 0,
  "HTTP::Status" => 0,
  "HTTP::Tiny::SPDY" => 0,
  "IO::Handle" => 0,
  "IO::Socket" => 0,
  "IO::Socket::SSL" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "Net::SPDY::Session" => 0,
  "Net::Server::PreFork" => 0,
  "Net::Server::SIG" => 0,
  "Plack::LWPish" => 0,
  "Plack::Runner" => 0,
  "Plack::TempBuffer" => 0,
  "Plack::Test::Suite" => 0,
  "Plack::Util" => 0,
  "Socket" => 0,
  "Test::More" => 0,
  "base" => 0,
  "constant" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



