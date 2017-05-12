
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Apply iTunes-like metadata to an mp4 file.",
  "AUTHOR" => "Andrew Jones <andrew\@arjones.co.uk>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-MP4Meta",
  "EXE_FILES" => [
    "bin/mp4meta"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::MP4Meta",
  "PREREQ_PM" => {
    "App::Cmd::Setup" => 0,
    "AtomicParsley::Command" => 0,
    "AtomicParsley::Command::Tags" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "LWP::Simple" => 0,
    "Module::Load" => 0,
    "Object::Tiny" => 0,
    "Try::Tiny" => 0,
    "WebService::OMDB" => 0,
    "WebService::TVDB" => "1.122800",
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "App::Cmd::Tester" => 0,
    "File::Copy" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Net::Ping" => 0,
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::MockObject" => 0,
    "Test::More" => "0.88",
    "WebService::TVDB::Series" => 0,
    "base" => 0,
    "lib" => 0
  },
  "VERSION" => "1.153340",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Cmd::Setup" => 0,
  "App::Cmd::Tester" => 0,
  "AtomicParsley::Command" => 0,
  "AtomicParsley::Command::Tags" => 0,
  "File::Copy" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "FindBin" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "LWP::Simple" => 0,
  "Module::Load" => 0,
  "Net::Ping" => 0,
  "Object::Tiny" => 0,
  "Test::Class" => 0,
  "Test::Exception" => 0,
  "Test::MockObject" => 0,
  "Test::More" => "0.88",
  "Try::Tiny" => 0,
  "WebService::OMDB" => 0,
  "WebService::TVDB" => "1.122800",
  "WebService::TVDB::Series" => 0,
  "base" => 0,
  "constant" => 0,
  "lib" => 0,
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



