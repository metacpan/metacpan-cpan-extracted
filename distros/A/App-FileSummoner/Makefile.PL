
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Makes file creation easier!',
  'AUTHOR' => 'Marian Schubert <marian.schubert@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'App-FileSummoner',
  'EXE_FILES' => [
    'bin/summon-file'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::FileSummoner',
  'PREREQ_PM' => {
    'Exporter' => '0',
    'File::Basename' => '0',
    'File::Spec' => '0',
    'Moose' => '0',
    'Template' => '0'
  },
  'VERSION' => '0.005',
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



