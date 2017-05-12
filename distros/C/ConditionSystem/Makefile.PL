
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A Common Lisp like condition/restart system for exceptions',
  'AUTHOR' => 'Oliver Charles',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'ConditionSystem',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'ConditionSystem',
  'PREREQ_PM' => {
    'Moose' => '1.16',
    'Scalar::Util' => '1.23',
    'Scope::Upper' => '0.12',
    'Sub::Exporter' => '0.982',
    'Test::More' => '0.96',
    'Throwable' => '0.102080',
    'Try::Tiny' => '0.07'
  },
  'VERSION' => '0.02',
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



