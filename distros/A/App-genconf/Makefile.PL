
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "The world's simplest config file generator",
  "AUTHOR" => "Matt Finkel <fffinkel\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-genconf",
  "EXE_FILES" => [
    "bin/genconf"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::genconf",
  "PREREQ_PM" => {
    "File::Find" => "1.23",
    "Getopt::Long" => "2.42",
    "Path::Class" => 0,
    "Template" => "2.25",
    "Try::Tiny" => "0.18",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.006",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Find" => "1.23",
  "Getopt::Long" => "2.42",
  "Path::Class" => 0,
  "Template" => "2.25",
  "Try::Tiny" => "0.18",
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



