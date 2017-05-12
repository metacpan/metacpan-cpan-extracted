
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "PCRE string checking for Rx (experimental)",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-Rx-Type-PCRE",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::Rx::Type::PCRE",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Rx" => "0.004",
    "Data::Rx::CommonType::EasyNew" => 0,
    "parent" => 0,
    "re::engine::PCRE" => "0.15",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Rx" => "0.004",
    "Test::More" => "0.96"
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Rx" => "0.004",
  "Data::Rx::CommonType::EasyNew" => 0,
  "Test::More" => "0.96",
  "parent" => 0,
  "re::engine::PCRE" => "0.15",
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



