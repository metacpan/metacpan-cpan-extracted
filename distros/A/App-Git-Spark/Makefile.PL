
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Plot your git commit history on the command line with sparklines",
  "AUTHOR" => "Eric Johnson <cpan at iijo dot nospamthanks dot org>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "List::Util" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Git-Spark",
  "EXE_FILES" => [
    "bin/git-spark",
    "bin/git-vspark"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Git::Spark",
  "PREREQ_PM" => {
    "DateTime" => 0,
    "Encode" => 0,
    "Getopt::Long::Descriptive" => 0,
    "List::AllUtils" => 0,
    "Math::Round" => 0,
    "Term::Spark" => 0,
    "Term::Vspark" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.006",
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



