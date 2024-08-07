# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.008.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Command-line interface to Software::License",
  "AUTHOR" => "Florian Ragwitz <rafl\@debian.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-Software-License",
  "EXE_FILES" => [
    "script/software-license"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "App::Software::License",
  "PREREQ_PM" => {
    "Config::Any" => 0,
    "File::HomeDir" => 0,
    "File::Spec::Functions" => 0,
    "Module::Runtime" => 0,
    "Moo" => "1.001000",
    "MooX::Options" => 0,
    "Software::License" => 0,
    "namespace::autoclean" => "0.16",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => "0.88",
    "Test::Warnings" => 0
  },
  "VERSION" => "0.11",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Config::Any" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::HomeDir" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "Module::Runtime" => 0,
  "Moo" => "1.001000",
  "MooX::Options" => 0,
  "Software::License" => 0,
  "Test::More" => "0.88",
  "Test::Warnings" => 0,
  "namespace::autoclean" => "0.16",
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
