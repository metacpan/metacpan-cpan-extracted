
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'English to Korean translate utility',
  'AUTHOR' => 'hshong <hshong@perl.kr>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Acme-eng2kor',
  'EXE_FILES' => [
    'bin/eng2kor'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::eng2kor',
  'PREREQ_PM' => {
    'Any::Moose' => '0',
    'Const::Fast' => '0',
    'Encode' => '0',
    'Getopt::Long' => '0',
    'HTTP::Request' => '0',
    'HTTP::Response' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'Pod::Usage' => '0',
    'URI::Escape' => '0',
    'namespace::autoclean' => '0',
    'utf8' => '0'
  },
  'VERSION' => 'v0.0.2',
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



