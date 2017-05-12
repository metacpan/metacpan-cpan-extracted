
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "efficiently retrieve and search trees with DBIx::Class",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-Class-MaterializedPath",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Class::MaterializedPath",
  "PREREQ_PM" => {
    "Class::C3::Componentised" => "1.001",
    "DBIx::Class" => "0.08196",
    "DBIx::Class::Helpers" => "2.007004",
    "DBIx::Introspector" => 0,
    "Module::Runtime" => 0,
    "SQL::Translator" => "0.11011",
    "Sub::Current" => "0.02",
    "Try::Tiny" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Deep" => "0.11",
    "Test::More" => "0.98"
  },
  "VERSION" => "0.002001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::C3::Componentised" => "1.001",
  "DBIx::Class" => "0.08196",
  "DBIx::Class::Helpers" => "2.007004",
  "DBIx::Introspector" => 0,
  "Module::Runtime" => 0,
  "SQL::Translator" => "0.11011",
  "Sub::Current" => "0.02",
  "Test::Deep" => "0.11",
  "Test::More" => "0.98",
  "Try::Tiny" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



