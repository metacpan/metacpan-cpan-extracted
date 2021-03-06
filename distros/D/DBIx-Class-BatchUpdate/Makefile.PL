# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.043.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Update batches of DBIC rows with as few queries as possible",
  "AUTHOR" => "Johan Lindstrom <johanl\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "DBIx-Class-BatchUpdate",
  "LICENSE" => "perl",
  "NAME" => "DBIx::Class::BatchUpdate",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DBIx::Class" => 0,
    "Moo" => 0,
    "Storable" => 0,
    "autobox::Core" => 0,
    "base" => 0,
    "strict" => 0,
    "true" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Differences" => 0,
    "Test::Exception" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0
  },
  "VERSION" => "1.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "DBIx::Class" => 0,
  "Moo" => 0,
  "Storable" => 0,
  "Test::Differences" => 0,
  "Test::Exception" => 0,
  "Test::MockObject" => 0,
  "Test::More" => 0,
  "autobox::Core" => 0,
  "base" => 0,
  "strict" => 0,
  "true" => 0,
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
