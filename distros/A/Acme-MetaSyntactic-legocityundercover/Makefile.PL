
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "LEGO City Undercover theme",
  "AUTHOR" => "Chris Williams",
  "BUILD_REQUIRES" => {
    "Test::MetaSyntactic" => 0,
    "Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Acme-MetaSyntactic-legocityundercover",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Acme::MetaSyntactic::legocityundercover",
  "PREREQ_PM" => {
    "Acme::MetaSyntactic::List" => "1.001"
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.47"
  },
  "VERSION" => "0.02",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Acme::MetaSyntactic::List" => "1.001",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Test::MetaSyntactic" => 0,
  "Test::More" => "0.47"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



