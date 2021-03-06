# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.036.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "An asynchronous library for InfluxDB time-series database",
  "AUTHOR" => "Alex J. G. Burzy\x{144}ski <ajgb\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.28"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "Module::Build" => "0.28"
  },
  "DISTNAME" => "AnyEvent-InfluxDB",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::InfluxDB",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::HTTP" => 0,
    "AnyEvent::TLS" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "Moo" => 0,
    "URI" => 0,
    "URI::Encode::XS" => 0,
    "URI::QueryParam" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.0.2.0",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "AnyEvent" => 0,
  "AnyEvent::HTTP" => 0,
  "AnyEvent::TLS" => 0,
  "ExtUtils::MakeMaker" => 0,
  "JSON" => 0,
  "List::MoreUtils" => 0,
  "Module::Build" => "0.28",
  "Moo" => 0,
  "URI" => 0,
  "URI::Encode::XS" => 0,
  "URI::QueryParam" => 0,
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
