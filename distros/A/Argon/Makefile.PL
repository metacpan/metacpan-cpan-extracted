# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.008.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple, fast, and flexible distributed computing",
  "AUTHOR" => "Jeff Ober <sysread\@fastmail.fm>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Argon",
  "EXE_FILES" => [
    "bin/ar-manager",
    "bin/ar-worker"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "Argon",
  "PREREQ_PM" => {
    "AnyEvent" => "7.14",
    "Carp" => "1.38",
    "Class::Load" => "0.24",
    "Const::Fast" => "0.014",
    "Crypt::CBC" => "2.33",
    "Crypt::Rijndael" => "1.13",
    "Data::Dump::Streamer" => "2.40",
    "Data::UUID" => "1.221",
    "Getopt::Long::Descriptive" => "0.100",
    "List::Util" => "1.49",
    "Moose" => "2.2006",
    "Path::Tiny" => "0.104",
    "Scalar::Util" => "1.49",
    "Sereal::Decoder" => "4.002",
    "Sereal::Encoder" => "4.002",
    "Test2::Bundle::Extended" => "0.000083",
    "Time::HiRes" => "1.9746",
    "Try::Catch" => "1.1.0",
    "parent" => "0.234"
  },
  "TEST_REQUIRES" => {
    "Devel::Refcount" => "0.10",
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Path::Tiny" => "0.104",
    "Test2::Bundle::Extended" => "0.000083",
    "Test::More" => 0,
    "Test::Pod" => "1.41",
    "Test::Refcount" => "0.08"
  },
  "VERSION" => "0.18",
  "test" => {
    "TESTS" => "t/*.t t/Argon/*.t"
  }
);


my %FallbackPrereqs = (
  "AnyEvent" => "7.14",
  "Carp" => "1.38",
  "Class::Load" => "0.24",
  "Const::Fast" => "0.014",
  "Crypt::CBC" => "2.33",
  "Crypt::Rijndael" => "1.13",
  "Data::Dump::Streamer" => "2.40",
  "Data::UUID" => "1.221",
  "Devel::Refcount" => "0.10",
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Getopt::Long::Descriptive" => "0.100",
  "List::Util" => "1.49",
  "Moose" => "2.2006",
  "Path::Tiny" => "0.104",
  "Scalar::Util" => "1.49",
  "Sereal::Decoder" => "4.002",
  "Sereal::Encoder" => "4.002",
  "Test2::Bundle::Extended" => "0.000083",
  "Test::More" => 0,
  "Test::Pod" => "1.41",
  "Test::Refcount" => "0.08",
  "Time::HiRes" => "1.9746",
  "Try::Catch" => "1.1.0",
  "parent" => "0.234"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
