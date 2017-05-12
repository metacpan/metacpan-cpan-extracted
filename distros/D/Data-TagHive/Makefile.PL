
use strict;
use warnings;

use 5.012000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "hierarchical tags with values",
  "AUTHOR" => "Ricardo Signes <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-TagHive",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::TagHive",
  "PREREQ_PM" => {
    "Carp" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Sub::Exporter" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.96",
    "Try::Tiny" => 0,
    "constant" => 0,
    "lib" => 0,
    "strict" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Sub::Exporter" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "0.96",
  "Try::Tiny" => 0,
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



