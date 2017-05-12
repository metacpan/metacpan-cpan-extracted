
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Brightcove Media API Wrapper',
  'AUTHOR' => 'Maroun NAJM <mnajm@cinemoz.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Brightcove-MAPI',
  'EXE_FILES' => [],
  'LICENSE' => 'bsd',
  'NAME' => 'Brightcove::MAPI',
  'PREREQ_PM' => {
    'Any::Moose' => '0',
    'JSON' => '0',
    'LWP::Protocol::https' => '6',
    'LWP::UserAgent' => '0',
    'URI' => '0'
  },
  'VERSION' => '0.1',
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



