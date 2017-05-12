
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'non-blocking interface to ZeroMQ sockets',
  'AUTHOR' => 'Jonathan Rockway <jrockway@cpan.org>',
  'BUILD_REQUIRES' => {
    'EV' => '0',
    'Test::More' => '0',
    'Test::TableDriven' => '0',
    'ZeroMQ::Raw::Context' => '0',
    'ok' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'AnyEvent-ZeroMQ',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'AnyEvent::ZeroMQ',
  'PREREQ_PM' => {
    'AnyEvent' => '0',
    'Carp' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'MooseX::Aliases' => '0',
    'MooseX::Role::Parameterized' => '0',
    'MooseX::Traits' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'MooseX::Types::Set::Object' => '0',
    'POSIX' => '0',
    'Params::Util' => '0',
    'Regexp::Common' => '0',
    'Scalar::Util' => '0',
    'Try::Tiny' => '0',
    'ZeroMQ::Raw' => '0',
    'ZeroMQ::Raw::Constants' => '0',
    'namespace::autoclean' => '0',
    'true' => '0'
  },
  'VERSION' => '0.01',
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



