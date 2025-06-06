# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;



use ExtUtils::MakeMaker 7.1101;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Run DDL on online databases safely",
  "AUTHOR" => "Grant Street Group <developers\@grantstreet.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.1101"
  },
  "DISTNAME" => "DBIx-OnlineDDL",
  "LICENSE" => "artistic_2",
  "NAME" => "DBIx::OnlineDDL",
  "PREREQ_PM" => {
    "Class::Load" => 0,
    "DBI::Const::GetInfoType" => 0,
    "DBIx::BatchChunker" => 0,
    "DBIx::ParseError::MySQL" => 0,
    "Eval::Reversible" => 0,
    "List::Util" => "1.44",
    "Moo" => 0,
    "MooX::StrictConstructor" => 0,
    "Sub::Util" => 0,
    "Term::ProgressBar" => 0,
    "Types::Common::Numeric" => 0,
    "Types::Standard" => 0,
    "namespace::clean" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "DBI" => "1.635",
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "Env" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Import::Into" => 0,
    "Path::Class" => 0,
    "Path::Class::File" => 0,
    "Test2::Bundle::More" => 0,
    "Test2::Tools::Compare" => 0,
    "Test2::Tools::Exception" => 0,
    "Test2::Tools::Explain" => 0,
    "Test::More" => 0,
    "base" => 0,
    "lib" => 0,
    "parent" => 0,
    "strict" => 0,
    "utf8" => 0
  },
  "VERSION" => "v1.1.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::Load" => 0,
  "DBI" => "1.635",
  "DBI::Const::GetInfoType" => 0,
  "DBIx::BatchChunker" => 0,
  "DBIx::Class::Core" => 0,
  "DBIx::Class::Schema" => 0,
  "DBIx::ParseError::MySQL" => 0,
  "Env" => 0,
  "Eval::Reversible" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Import::Into" => 0,
  "List::Util" => "1.44",
  "Moo" => 0,
  "MooX::StrictConstructor" => 0,
  "Path::Class" => 0,
  "Path::Class::File" => 0,
  "Sub::Util" => 0,
  "Term::ProgressBar" => 0,
  "Test2::Bundle::More" => 0,
  "Test2::Tools::Compare" => 0,
  "Test2::Tools::Exception" => 0,
  "Test2::Tools::Explain" => 0,
  "Test::More" => 0,
  "Types::Common::Numeric" => 0,
  "Types::Standard" => 0,
  "base" => 0,
  "lib" => 0,
  "namespace::clean" => 0,
  "parent" => 0,
  "strict" => 0,
  "utf8" => 0,
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
