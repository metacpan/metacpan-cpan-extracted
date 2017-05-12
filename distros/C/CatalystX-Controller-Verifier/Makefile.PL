
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Moose Role for verifying request parameters on a per action basis.',
  'AUTHOR' => 'J. Shirley <jshirley@cpan.org>',
  'BUILD_REQUIRES' => {
    'Catalyst' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Request' => '0',
    'Catalyst::Test' => '0',
    'FindBin' => '0',
    'Moose' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'CatalystX-Controller-Verifier',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'CatalystX::Controller::Verifier',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Catalyst' => '0',
    'Data::Manager' => '0.07',
    'Data::Verifier' => '0',
    'Message::Stack' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0'
  },
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



