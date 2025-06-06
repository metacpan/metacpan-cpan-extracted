# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.037.
use strict;
use warnings;

use 5.014;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "CLI to Net::OpenSSH that runs the same command via SSH on many remote servers at the same time",
  "AUTHOR" => "Hunter McMillen <mcmillhj\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-SSH-Cluster",
  "EXE_FILES" => [
    "bin/clusterssh"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.014",
  "NAME" => "App::SSH::Cluster",
  "PREREQ_PM" => {
    "List::MoreUtils" => 0,
    "MooseX::App::Simple" => 0,
    "MooseX::Types::Moose" => 0,
    "Net::OpenSSH::Parallel" => 0,
    "YAML::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "List::MoreUtils" => 0,
  "MooseX::App::Simple" => 0,
  "MooseX::Types::Moose" => 0,
  "Net::OpenSSH::Parallel" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "YAML::Tiny" => 0,
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
