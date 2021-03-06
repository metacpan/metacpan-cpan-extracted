# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.036.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Run test programs as soon as they are modified",
  "AUTHOR" => "Gregor Goldbach <glauschwuffel\@nomaden.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-autotest",
  "EXE_FILES" => [
    "scripts/autotest"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "App::autotest",
  "PREREQ_PM" => {
    "Cwd" => 0,
    "File::ChangeNotify" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "List::MoreUtils" => 0,
    "Moose" => 0,
    "TAP::Harness" => 0,
    "Test::Differences" => "0.63",
    "Test::Spec" => "0.46",
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Basename" => 0,
    "TAP::Parser::Aggregator" => 0,
    "Test::Differences" => "0.63",
    "Test::Mock::Guard" => 0,
    "Test::Spec" => "0.46",
    "constant" => 0
  },
  "VERSION" => "0.006",
  "test" => {
    "TESTS" => "t/*.t t/features/*.t t/integration/*.t t/unit/*.t"
  }
);


my %FallbackPrereqs = (
  "Cwd" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Basename" => 0,
  "File::ChangeNotify" => 0,
  "File::Find" => 0,
  "File::Spec" => 0,
  "FindBin" => 0,
  "List::MoreUtils" => 0,
  "Moose" => 0,
  "TAP::Harness" => 0,
  "TAP::Parser::Aggregator" => 0,
  "Test::Differences" => "0.63",
  "Test::Mock::Guard" => 0,
  "Test::Spec" => "0.46",
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
