
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Automatically Learns Decision Trees",
  "AUTHOR" => "Ken Williams <kwilliams\@cpan.org>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "Test" => 0,
    "Test::More" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AI-DecisionTree",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AI::DecisionTree",
  "PREREQ_PM" => {
    "Carp" => 0,
    "GraphViz" => 0,
    "strict" => 0,
    "vars" => 0
  },
  "VERSION" => "0.11",
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



