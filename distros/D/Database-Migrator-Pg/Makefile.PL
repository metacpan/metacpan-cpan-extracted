# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.009.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Database::Migrator implementation for Postgres",
  "AUTHOR" => "Dave Rolsky <autarch\@urth.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Database-Migrator-Pg",
  "LICENSE" => "artistic_2",
  "NAME" => "Database::Migrator::Pg",
  "PREREQ_PM" => {
    "Database::Migrator" => "0.07",
    "Database::Migrator::Core" => 0,
    "Database::Migrator::Types" => 0,
    "Moose" => 0,
    "Pg::CLI" => "0.11",
    "Pg::CLI::createdb" => 0,
    "Pg::CLI::dropdb" => 0,
    "Pg::CLI::psql" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => "0.96"
  },
  "VERSION" => "0.06",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Database::Migrator" => "0.07",
  "Database::Migrator::Core" => 0,
  "Database::Migrator::Types" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Moose" => 0,
  "Pg::CLI" => "0.11",
  "Pg::CLI::createdb" => 0,
  "Pg::CLI::dropdb" => 0,
  "Pg::CLI::psql" => 0,
  "Test::More" => "0.96",
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
