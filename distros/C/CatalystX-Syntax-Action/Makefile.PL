
use strict;
use warnings;

BEGIN { require 5.008008; }

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Semantically meaningful Catalyst Actions with signatures',
  'AUTHOR' => 'John Napiorkowski <jjnapiork@cpan.org>',
  'BUILD_REQUIRES' => {
    'Catalyst::Runtime' => '5.80',
    'FindBin' => '0',
    'HTTP::Request::Common' => '0',
    'Moose' => '2.0007',
    'Test::More' => '0.98',
    'namespace::autoclean' => '0.12',
    'syntax' => '0.003'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'CatalystX-Syntax-Action',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'CatalystX::Syntax::Action',
  'PREREQ_PM' => {
    'B::Hooks::EndOfScope' => '0.09',
    'Carp' => '0',
    'Devel::Declare' => '0.006004',
    'parent' => '0.225'
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



