
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "An implementation of the Paxos protocol",
  "AUTHOR" => "Chris Prather <chris\@prather.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "Test::More" => 0,
    "strict" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Algorithm-Paxos",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Algorithm::Paxos",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Moose::Role" => 0,
    "Sub::Exporter" => 0,
    "Sub::Exporter::Util" => 0,
    "Throwable::Error" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


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



