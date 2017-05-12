
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "InputMonster sources for common Catalyst sources",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-InputMonster-Util-Catalyst",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::InputMonster::Util::Catalyst",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::InputMonster" => "0.007",
    "Data::InputMonster::Util" => 0,
    "Sub::Exporter" => 0,
    "Sub::Exporter::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::InputMonster" => "0.007",
    "Test::Deep" => 0,
    "Test::More" => "0.96"
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::InputMonster" => "0.007",
  "Data::InputMonster::Util" => 0,
  "Sub::Exporter" => 0,
  "Sub::Exporter::Util" => 0,
  "Test::Deep" => 0,
  "Test::More" => "0.96",
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



