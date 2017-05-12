
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "experimental / perl types",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-Rx-TypeBundle-Perl",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::Rx::TypeBundle::Perl",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Rx" => "0.200002",
    "Data::Rx::CommonType::EasyNew" => 0,
    "Data::Rx::TypeBundle" => 0,
    "Scalar::Util" => 0,
    "base" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Rx" => "0.200002",
    "Test::More" => "0.96"
  },
  "VERSION" => "0.009",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Rx" => "0.200002",
  "Data::Rx::CommonType::EasyNew" => 0,
  "Data::Rx::TypeBundle" => 0,
  "Scalar::Util" => 0,
  "Test::More" => "0.96",
  "base" => 0,
  "parent" => 0,
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



