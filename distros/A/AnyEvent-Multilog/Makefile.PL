
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'event-driven interface to a multilog process',
  'AUTHOR' => 'Jonathan Rockway <jrockway@cpan.org>',
  'BUILD_REQUIRES' => {
    'Directory::Scratch' => '0',
    'File::Which' => '0',
    'Sub::Exporter' => '0',
    'Test::Builder' => '0',
    'Test::More' => '0',
    'ok' => '0',
    't::lib::multilog' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'AnyEvent-Multilog',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'AnyEvent::Multilog',
  'PREREQ_PM' => {
    'AnyEvent::Subprocess' => '0',
    'AnyEvent::Subprocess::Job::Delegate::Handle' => '0',
    'Moose' => '0',
    'MooseX::Types::Path::Class' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '1.102861',
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



