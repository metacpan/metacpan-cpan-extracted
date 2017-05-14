
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Bitcard authentication verification',
  'AUTHOR' => 'Ask Bjørn Hansen <ask@develooper.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Authen-Bitcard',
  'EXE_FILES' => [],
  'LICENSE' => 'apache',
  'NAME' => 'Authen::Bitcard',
  'PREREQ_PM' => {
    'Class::ErrorHandler' => '0',
    'Digest::SHA' => '0',
    'HTTP::Status' => '0',
    'JSON' => '2.12',
    'LWP::Protocol::https' => '0',
    'LWP::UserAgent' => '0',
    'MIME::Base64' => '0',
    'Math::BigInt' => '0',
    'URI' => '1.22'
  },
  'VERSION' => '0.90',
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



