# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.025.
use strict;
use warnings;



use ExtUtils::MakeMaker 7.1101;

my %WriteMakefileArgs = (
  "ABSTRACT" => "DBIx::Connector with block retry support",
  "AUTHOR" => "Grant Street Group <developers\@grantstreet.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.1101"
  },
  "DISTNAME" => "DBIx-Connector-Retry",
  "LICENSE" => "artistic_2",
  "NAME" => "DBIx::Connector::Retry",
  "PREREQ_PM" => {
    "DBIx::Connector" => 0,
    "Moo" => 0,
    "Scalar::Util" => 0,
    "Types::Common::Numeric" => 0,
    "Types::Standard" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "DBD::SQLite" => 0,
    "DBI" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Path::Class" => 0,
    "Test2::Bundle::More" => 0,
    "Test2::Tools::Compare" => 0,
    "Test2::Tools::Exception" => 0,
    "Test2::Tools::Explain" => 0,
    "Test::More" => 0,
    "lib" => 0
  },
  "VERSION" => "v0.900.3",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DBD::SQLite" => 0,
  "DBI" => 0,
  "DBIx::Connector" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moo" => 0,
  "Path::Class" => 0,
  "Scalar::Util" => 0,
  "Test2::Bundle::More" => 0,
  "Test2::Tools::Compare" => 0,
  "Test2::Tools::Exception" => 0,
  "Test2::Tools::Explain" => 0,
  "Test::More" => 0,
  "Types::Common::Numeric" => 0,
  "Types::Standard" => 0,
  "lib" => 0,
  "namespace::clean" => 0,
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
