
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a DateTime object with different math",
  "AUTHOR" => "Mark Dominus <mjd\@plover.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DateTime-Moonpig",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DateTime::Moonpig",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DateTime" => 0,
    "Scalar::Util" => 0,
    "Sub::Install" => 0,
    "base" => 0,
    "namespace::autoclean" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "Try::Tiny" => 0,
    "lib" => 0
  },
  "VERSION" => "1.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "DateTime" => 0,
  "Scalar::Util" => 0,
  "Sub::Install" => 0,
  "Test::Fatal" => 0,
  "Test::More" => 0,
  "Try::Tiny" => 0,
  "base" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
  "overload" => 0,
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



