
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Back-channel vi, a shell utility to proxy commands back over ssh",
  "AUTHOR" => "Grant McLean <grantm\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-BCVI",
  "EXE_FILES" => [
    "bin/bcvi"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::BCVI",
  "PREREQ_PM" => {},
  "VERSION" => "3.09",
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



