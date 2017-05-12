
use strict;
use warnings;

use 5.008000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "show time and month info",
  "AUTHOR" => "Ivan Bessarabov <ivan\@bessarabov.ru>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-D",
  "EXE_FILES" => [
    "bin/d"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::D",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Date" => 0,
    "Term::ANSIColor" => 0,
    "open" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "1.3.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::Date" => 0,
  "Term::ANSIColor" => 0,
  "open" => 0,
  "strict" => 0,
  "utf8" => 0,
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



