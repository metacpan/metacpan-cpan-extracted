
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Easily traverse and transform immutable data',
  'AUTHOR' => 'Oliver Charles',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Data-Zipper',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::Zipper',
  'PREREQ_PM' => {
    'Moose' => '1.19',
    'MooseX::Role::Parameterized' => '0.19',
    'MooseX::Types' => '0.24',
    'MooseX::Types::Structured' => '0.24',
    'Test::More' => '0.96',
    'namespace::autoclean' => '0.11'
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



