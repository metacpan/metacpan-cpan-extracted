
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.009.
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "YQL Perl interface for the Y! Query API",
  "AUTHOR" => "Ali Anari <ali\@anari.me>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Business-YQL",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Business::YQL",
  "PREREQ_PM" => {
    "Carp" => 0,
    "HTTP::Request::Common" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => "1.35",
    "Log::Any" => "0.15",
    "Log::Any::Adapter" => "0.11",
    "Moo" => "1.004002",
    "Try::Tiny" => 0,
    "URI" => 0,
    "URI::QueryParam" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Log::Any::Adapter" => "0.11",
    "Log::Dispatch" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "File::Spec" => 0,
  "HTTP::Request::Common" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON" => 0,
  "LWP::UserAgent" => 0,
  "List::Util" => "1.35",
  "Log::Any" => "0.15",
  "Log::Any::Adapter" => "0.11",
  "Log::Dispatch" => 0,
  "Moo" => "1.004002",
  "Test::More" => 0,
  "Test::Most" => 0,
  "Try::Tiny" => 0,
  "URI" => 0,
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



