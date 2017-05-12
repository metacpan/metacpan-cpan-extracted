
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Adds thresholding to hierarchical clustering of Algorithm::Cluster',
  'AUTHOR' => 'Chad A. Davis <chad.a.davis@gmail.com>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Algorithm-Cluster-Thresh',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Algorithm::Cluster::Thresh',
  'PREREQ_PM' => {
    'Algorithm::Cluster' => '0'
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



