
use strict;
use warnings;

use 5.008009;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Redis backend for Dancer Session Engine",
  "AUTHOR" => "Anton Gerasimov <chim\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::More" => "0.98",
    "Test::Pod" => "1.22"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dancer-Session-Redis",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer::Session::Redis",
  "PREREQ_PM" => {
    "Carp" => "1.26",
    "Dancer" => "1.3072",
    "Redis" => "1.955",
    "Storable" => "2.27",
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.22",
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



