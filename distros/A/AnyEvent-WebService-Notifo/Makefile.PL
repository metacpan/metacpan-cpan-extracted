
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'AnyEvent-powered client for the notifo.com API',
  'AUTHOR' => 'Pedro Melo <melo@simplicidade.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'AnyEvent-WebService-Notifo',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'AnyEvent::WebService::Notifo',
  'PREREQ_PM' => {
    'AnyEvent::HTTP' => '0',
    'Protocol::Notifo' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.001',
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



