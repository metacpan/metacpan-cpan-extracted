
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl client to the bloomd server",
  "AUTHOR" => "Damien \"dams\" Krotkine",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Bloomd-Client",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Bloomd::Client",
  "PREREQ_PM" => {
    "Config" => 0,
    "IO::Socket::INET" => 0,
    "List::MoreUtils" => 0,
    "Moo" => 0,
    "Type::Tiny" => "0.026"
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::TCP" => 0
  },
  "VERSION" => "0.27",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Config" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IO::Socket::INET" => 0,
  "IPC::Open3" => 0,
  "List::MoreUtils" => 0,
  "Module::Build" => "0.3601",
  "Moo" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "Test::TCP" => 0,
  "Type::Tiny" => "0.026"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



