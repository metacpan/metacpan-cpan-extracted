
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Module to try to perform an action, with various ways of retrying and sleeping between retries.",
  "AUTHOR" => "Damien \"dams\" Krotkine",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Action-Retry",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Action::Retry",
  "PREREQ_PM" => {
    "Math::Fibonacci" => 0,
    "Module::Runtime" => 0,
    "Moo" => 0,
    "Scalar::Util" => 0,
    "Time::HiRes" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.24",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Math::Fibonacci" => 0,
  "Module::Build" => "0.3601",
  "Module::Runtime" => 0,
  "Moo" => 0,
  "Scalar::Util" => 0,
  "Test::More" => 0,
  "Time::HiRes" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



