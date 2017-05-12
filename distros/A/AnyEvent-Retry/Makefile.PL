
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'try something until it works',
  'AUTHOR' => 'Jonathan Rockway <jrockway@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::Exception' => '0',
    'Test::More' => '0',
    'ok' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'AnyEvent-Retry',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'AnyEvent::Retry',
  'PREREQ_PM' => {
    'AnyEvent' => '0',
    'Math::Fibonacci' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Common::Numeric' => '0',
    'MooseX::Types::Moose' => '0',
    'Scalar::Util' => '0',
    'Try::Tiny' => '0',
    'namespace::autoclean' => '0',
    'true' => '0'
  },
  'VERSION' => '0.03',
  'test' => {
    'TESTS' => 't/*.t t/intervals/*.t'
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



