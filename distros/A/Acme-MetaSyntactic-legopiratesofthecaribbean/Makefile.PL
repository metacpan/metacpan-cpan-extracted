
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "LEGO Pirates of the Caribbean theme",
  "AUTHOR" => "Chris Williams",
  "BUILD_REQUIRES" => {
    "Test::MetaSyntactic" => 0,
    "Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Acme-MetaSyntactic-legopiratesofthecaribbean",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Acme::MetaSyntactic::legopiratesofthecaribbean",
  "PREREQ_PM" => {
    "Acme::MetaSyntactic::List" => "1.001"
  },
  "VERSION" => "0.02",
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



