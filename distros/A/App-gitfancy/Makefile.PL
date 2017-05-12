
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "shows `git log` with a more readable graph",
  "AUTHOR" => "Geunyoung Park <gypark\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-gitfancy",
  "EXE_FILES" => [
    "bin/git-fancy"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::gitfancy",
  "PREREQ_PM" => {
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "autodie" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.003",
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



