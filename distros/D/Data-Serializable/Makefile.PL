
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Moose role that adds serialization support to any class",
  "AUTHOR" => "Robin Smidsr\303\270d <robin\@smidsrod.no>",
  "BUILD_REQUIRES" => {
    "JSON" => 0,
    "Moose" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-Serializable",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::Serializable",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Module::Runtime" => 0,
    "Moose::Role" => 0,
    "Storable" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.41.0",
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



