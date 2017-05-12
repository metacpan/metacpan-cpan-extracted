
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Pack data structures so only real content remains',
  'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::Differences' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Data-Pack',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::Pack',
  'PREREQ_PM' => {
    'Exporter' => '0',
    'Scalar::Util' => '0'
  },
  'VERSION' => '1.101611',
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



