
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a wrapper for AI::ANN',
  'AUTHOR' => 'Dan Collins <dcollin1@stevens.edu>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'DCOLLINS-ANN-Locals',
  'EXE_FILES' => [],
  'LICENSE' => 'gpl',
  'NAME' => 'DCOLLINS::ANN::Locals',
  'PREREQ_PM' => {
    'AI::ANN' => '0',
    'Inline::C' => '0',
    'Math::Libm' => '1.00',
    'Moose' => '2.00',
    'Storable' => '0'
  },
  'VERSION' => '0.004',
  'test' => {
    'TESTS' => 't/*.t'
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



