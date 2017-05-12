
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A wrapper for installing the Judy library',
  'AUTHOR' => 'Josh Jore <jjore@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Alien-Judy',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Alien::Judy',
  'PREREQ_PM' => {
    'Config' => '0',
    'Cwd' => '0',
    'DynaLoader' => '0',
    'File::Spec' => '0',
    'Sub::Exporter' => '0',
    'vars' => '0'
  },
  'VERSION' => '0.27',
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



