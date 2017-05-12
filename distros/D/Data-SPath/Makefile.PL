
use strict;
use warnings;

 BEGIN { require 5.010_000; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'lookup on nested data with simple path notation',
  'AUTHOR' => 'Scott Beck <scottbeck@gmail.com>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Data-SPath',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::SPath',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Scalar::Util' => '0',
    'Sub::Exporter' => '0',
    'Text::Balanced' => '0'
  },
  'VERSION' => '0.0004',
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



