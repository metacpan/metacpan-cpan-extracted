# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.047.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Interface with a persistent document store",
  "AUTHOR" => "Dana M. Diederich <dana\@realms.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-MultiModule-Tasks-DocGateway",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "App::MultiModule::Tasks::DocGateway",
  "PREREQ_PM" => {
    "App::MultiModule::Task" => 0,
    "App::MultiModule::Test" => 0,
    "Postgres::Mongo" => 0,
    "Storable" => 0,
    "Test::More" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Slurp" => 0,
    "File::Temp" => 0,
    "IPC::Transit" => 0,
    "POSIX" => 0,
    "lib" => 0
  },
  "VERSION" => "1.161330",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::MultiModule::Task" => 0,
  "App::MultiModule::Test" => 0,
  "Data::Dumper" => 0,
  "File::Slurp" => 0,
  "File::Temp" => 0,
  "IPC::Transit" => 0,
  "POSIX" => 0,
  "Postgres::Mongo" => 0,
  "Storable" => 0,
  "Test::More" => 0,
  "lib" => 0,
  "parent" => 0,
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
