
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "automatically add \"to Hiveminder.com\" addrs",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Addex-Plugin-Hiveminder",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "App::Addex::Plugin::Hiveminder",
  "PREREQ_PM" => {
    "App::Addex::Entry" => 0,
    "Sub::Install" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.96"
  },
  "VERSION" => "0.006",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Addex::Entry" => 0,
  "Sub::Install" => 0,
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



