# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.014;

use ExtUtils::MakeMaker 7.64;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides Data::Chronicle-backed configuration storage",
  "AUTHOR" => "binary.com <BINARY\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.64"
  },
  "DISTNAME" => "App-Config-Chronicle",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.014",
  "NAME" => "App::Config::Chronicle",
  "PREREQ_PM" => {
    "Data::Chronicle" => "0.18",
    "Data::Chronicle::Reader" => 0,
    "Data::Chronicle::Subscriber" => 0,
    "Data::Chronicle::Writer" => 0,
    "Data::Hash::DotNotation" => 0,
    "Date::Utility" => 0,
    "Encode" => 0,
    "JSON::MaybeXS" => 0,
    "List::Util" => "1.29",
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types" => 0,
    "Syntax::Keyword::Try" => 0,
    "Time::HiRes" => 0,
    "YAML::XS" => 0,
    "constant" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Chronicle::Mock" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::CheckDeps" => "0.010",
    "Test::MockModule" => 0,
    "Test::MockObject" => 0,
    "Test::MockTime" => 0,
    "Test::More" => "0.98",
    "Test::Most" => "0.22",
    "Test::NoWarnings" => 0,
    "Test::Warn" => 0
  },
  "VERSION" => "0.07",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Chronicle" => "0.18",
  "Data::Chronicle::Mock" => 0,
  "Data::Chronicle::Reader" => 0,
  "Data::Chronicle::Subscriber" => 0,
  "Data::Chronicle::Writer" => 0,
  "Data::Hash::DotNotation" => 0,
  "Date::Utility" => 0,
  "Encode" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "FindBin" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON::MaybeXS" => 0,
  "List::Util" => "1.29",
  "Moose" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "MooseX::Types" => 0,
  "Syntax::Keyword::Try" => 0,
  "Test::CheckDeps" => "0.010",
  "Test::MockModule" => 0,
  "Test::MockObject" => 0,
  "Test::MockTime" => 0,
  "Test::More" => "0.98",
  "Test::Most" => "0.22",
  "Test::NoWarnings" => 0,
  "Test::Warn" => 0,
  "Time::HiRes" => 0,
  "YAML::XS" => 0,
  "constant" => 0,
  "namespace::autoclean" => 0,
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
