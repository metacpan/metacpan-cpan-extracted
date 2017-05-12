
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple, hierarchical user authorization for web applications, with optional support for plan-based (paid) services.",
  "AUTHOR" => "Ido Perlmuter <ido\@ido50.net>",
  "BUILD_REQUIRES" => {
    "Moo" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Abilities",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Abilities",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Hash::Merge" => 0,
    "Moo::Role" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.5",
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



