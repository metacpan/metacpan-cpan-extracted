
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Generate random contact data',
  'AUTHOR' => 'Dave Rolsky <autarch@urth.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.88',
    'Test::Requires' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Data-Random-Contact',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Data::Random::Contact',
  'PREREQ_PM' => {
    'Class::Load' => '0',
    'DateTime' => '0',
    'Moose' => '0',
    'MooseX::Types' => '0',
    'autodie' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.05',
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



