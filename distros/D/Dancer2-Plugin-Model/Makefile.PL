# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.037.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "gantry to hang a model layer onto Dancer2",
  "AUTHOR" => "Christian Walde <walde.christian\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dancer2-Plugin-Model",
  "EXE_FILES" => [],
  "LICENSE" => "unrestricted",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Dancer2::Plugin::Model",
  "PREREQ_PM" => {
    "Dancer2" => 0,
    "Dancer2::Plugin" => 0,
    "Dancer2::Plugin::AppRole::Helper" => 0,
    "Module::Runtime" => 0,
    "Moo::Role" => 0,
    "Types::Standard" => 0,
    "strictures" => 2
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::InDistDir" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.152120",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dancer2" => 0,
  "Dancer2::Plugin" => 0,
  "Dancer2::Plugin::AppRole::Helper" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Runtime" => 0,
  "Moo::Role" => 0,
  "Test::InDistDir" => 0,
  "Test::More" => 0,
  "Types::Standard" => 0,
  "strict" => 0,
  "strictures" => 2,
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
