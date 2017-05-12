
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'flexible, OO, asynchronous process spawning and management',
  'AUTHOR' => 'Jonathan Rockway <jrockway@cpan.org>',
  'BUILD_REQUIRES' => {
    'Scalar::Util' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'ok' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'AnyEvent-Subprocess',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'AnyEvent::Subprocess',
  'PREREQ_PM' => {
    'AnyEvent' => '0',
    'AnyEvent::Handle' => '0',
    'AnyEvent::Util' => '0',
    'Carp' => '0',
    'EV' => '4.0',
    'Event::Join' => '0.05',
    'IO::Pty' => '0',
    'JSON' => '2',
    'Moose' => '1.15',
    'Moose::Role' => '0',
    'MooseX::Clone' => '0',
    'MooseX::Role::Parameterized' => '0',
    'MooseX::StrictConstructor' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'MooseX::Types::Signal' => '0',
    'POSIX' => '0',
    'Sub::Exporter' => '0',
    'Try::Tiny' => '0',
    'namespace::autoclean' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => '1.102912',
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



