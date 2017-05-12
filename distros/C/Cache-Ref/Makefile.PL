
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Memory only cache of live references',
  'AUTHOR' => 'Yuval Kogman',
  'BUILD_REQUIRES' => {
    'Test::Moose' => '0',
    'Test::More' => '0',
    'ok' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Cache-Ref',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Cache::Ref',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Hash::Util::FieldHash::Compat' => '0',
    'List::Util' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'MooseX::Role::Parameterized' => '0',
    'Scalar::Util' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.04',
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



