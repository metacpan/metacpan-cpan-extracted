# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.043.
use strict;
use warnings;

use 5.014;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Object Orientated Interface to CloudFlare client API",
  "AUTHOR" => "Peter Roberts <me+dev\@peter-r.co.uk>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "CloudFlare-Client",
  "LICENSE" => "mit",
  "MIN_PERL_VERSION" => "5.014",
  "NAME" => "CloudFlare::Client",
  "PREREQ_PM" => {
    "JSON::MaybeXS" => 0,
    "Kavorka" => 0,
    "LWP::Protocol::https" => "6.02",
    "LWP::UserAgent" => "6.02",
    "Moose" => 0,
    "MooseX::StrictConstructor" => 0,
    "Readonly" => 0,
    "Throwable::Error" => 0,
    "Type::Library" => 0,
    "Type::Utils" => "0.039_12",
    "Types::Standard" => 0,
    "indirect" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "HTTP::Response" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "IPC::System::Simple" => 0,
    "JSON::Any" => 0,
    "Test::CPAN::Meta::JSON" => 0,
    "Test::Exception" => 0,
    "Test::LWP::UserAgent" => 0,
    "Test::Moose" => 0,
    "Test::More" => 0,
    "Test::RequiresInternet" => 0,
    "Test::TypeTiny" => 0,
    "Try::Tiny" => 0,
    "blib" => "1.01"
  },
  "VERSION" => "v0.55.4",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Spec" => 0,
  "HTTP::Response" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "IPC::System::Simple" => 0,
  "JSON::Any" => 0,
  "JSON::MaybeXS" => 0,
  "Kavorka" => 0,
  "LWP::Protocol::https" => "6.02",
  "LWP::UserAgent" => "6.02",
  "Moose" => 0,
  "MooseX::StrictConstructor" => 0,
  "Readonly" => 0,
  "Test::CPAN::Meta::JSON" => 0,
  "Test::Exception" => 0,
  "Test::LWP::UserAgent" => 0,
  "Test::Moose" => 0,
  "Test::More" => 0,
  "Test::RequiresInternet" => 0,
  "Test::TypeTiny" => 0,
  "Throwable::Error" => 0,
  "Try::Tiny" => 0,
  "Type::Library" => 0,
  "Type::Utils" => "0.039_12",
  "Types::Standard" => 0,
  "blib" => "1.01",
  "indirect" => 0,
  "mro" => 0,
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
