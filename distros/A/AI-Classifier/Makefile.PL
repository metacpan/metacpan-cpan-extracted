
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A convenient class for text classification",
  "AUTHOR" => "Zbigniew Lukasiak <zlukasiak\@opera.com>, Tadeusz So\305\233nierz <tsosnierz\@opera.com>",
  "BUILD_REQUIRES" => {
    "Data::Dumper" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AI-Classifier",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AI::Classifier",
  "PREREQ_PM" => {
    "AI::NaiveBayes" => "0.01",
    "AI::NaiveBayes::Learner" => 0,
    "Carp" => 0,
    "File::Find::Rule" => "0.32",
    "File::Spec" => 0,
    "List::Util" => 0,
    "Module::Load" => 0,
    "Moose" => "1.15",
    "MooseX::Storage" => "0.25",
    "Text::WordCounter" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.03",
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



