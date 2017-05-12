
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a moer tolernat verison of mehtod location",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Amce-CNA",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Amce::CNA",
  "PREREQ_PM" => {
    "Class::ISA" => 0,
    "Sub::Exporter" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.96"
  },
  "VERSION" => "0.066",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::ISA" => 0,
  "Sub::Exporter" => 0,
  "Test::More" => "0.96",
  "strict" => 0,
  "vars" => 0,
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



