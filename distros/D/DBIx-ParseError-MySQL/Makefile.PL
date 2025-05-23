# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;



use ExtUtils::MakeMaker 7.1101;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Error parser for MySQL",
  "AUTHOR" => "Grant Street Group <developers\@grantstreet.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.1101"
  },
  "DISTNAME" => "DBIx-ParseError-MySQL",
  "LICENSE" => "artistic_2",
  "NAME" => "DBIx::ParseError::MySQL",
  "PREREQ_PM" => {
    "Moo" => "2.00",
    "Scalar::Util" => 0,
    "Types::Standard" => "1.00"
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test2::Bundle::More" => 0,
    "Test::More" => 0
  },
  "VERSION" => "v1.0.4",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moo" => "2.00",
  "Scalar::Util" => 0,
  "Test2::Bundle::More" => 0,
  "Test::More" => 0,
  "Types::Standard" => "1.00"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
