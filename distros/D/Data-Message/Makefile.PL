
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "parse and build header-and-body messages (kinda like email)",
  "AUTHOR" => "Casey West, Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-Message",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::Message",
  "PREREQ_PM" => {
    "Email::Simple" => "1.92",
    "base" => 0,
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.96",
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.104",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Email::Simple" => "1.92",
  "Test::More" => "0.96",
  "base" => 0,
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



