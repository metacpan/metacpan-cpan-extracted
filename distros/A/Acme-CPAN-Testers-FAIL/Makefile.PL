
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'generate a FAILing test report',
  'AUTHOR' => 'Chris Williams <chris@bingosnet.co.uk>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.47'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Acme-CPAN-Testers-FAIL',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::CPAN::Testers::FAIL',
  'PREREQ_PM' => {},
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



