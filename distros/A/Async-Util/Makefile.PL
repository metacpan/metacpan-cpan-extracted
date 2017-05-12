
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "utilities for doing common async operations",
  "AUTHOR" => "Whitney Jackson <whitney\@cpan.org>",
  "BUILD_REQUIRES" => {
    "AnyEvent" => 0,
    "List::MoreUtils" => 0,
    "Test::More" => 0,
    "ok" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Async-Util",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Async::Util",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.01",
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



