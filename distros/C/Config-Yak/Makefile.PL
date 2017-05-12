
use strict;
use warnings;

use 5.010_000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a tree-based versatile config handler",
  "AUTHOR" => "Dominik Schulz <dominik.schulz\@gauner.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Config-Yak",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Config::Yak",
  "PREREQ_PM" => {
    "Config::Any" => 0,
    "Config::General" => 0,
    "Config::Tiny" => 0,
    "Data::Dumper" => 0,
    "Data::Structure::Util" => 0,
    "Data::Tree" => "0.16",
    "English" => 0,
    "Hash::Merge" => 0,
    "IO::Handle" => 0,
    "Log::Tree::RequiredLogger" => 0,
    "Module::Pluggable::Object" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Scalar::Util" => 0,
    "Try::Tiny" => 0,
    "autodie" => 0,
    "feature" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "FindBin" => 0,
    "Test::MockObject::Universal" => 0,
    "Test::More" => 0,
    "strict" => 0
  },
  "VERSION" => "0.23",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



