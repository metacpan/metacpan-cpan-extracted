
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Provides an opinionated method for verifying permissions on a per-action basis by inspecting the user.',
  'AUTHOR' => 'J. Shirley <jshirley@cpan.org>',
  'BUILD_REQUIRES' => {
    'Catalyst' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Test' => '0',
    'FindBin' => '0',
    'HTTP::Request::Common' => '0',
    'Moose' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Catalyst-TraitFor-Controller-PermissionCheck',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::TraitFor::Controller::PermissionCheck',
  'PREREQ_PM' => {
    'Catalyst::Plugin::Authentication' => '0',
    'Catalyst::Plugin::Session' => '0',
    'Catalyst::Plugin::Session::State::Cookie' => '0',
    'Catalyst::Runtime' => '0',
    'Message::Stack' => '0',
    'Moose::Role' => '0',
    'Try::Tiny' => '0'
  },
  'VERSION' => '0.04',
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



