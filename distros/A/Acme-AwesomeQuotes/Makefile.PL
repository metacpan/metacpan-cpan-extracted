
use strict;
use warnings;

BEGIN { require 5.008_003; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Make your text awesome!',
  'AUTHOR' => 'Marcus Smith <carwash@cpan.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Acme-AwesomeQuotes',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::AwesomeQuotes',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Exporter' => '0',
    'Unicode::Normalize' => '0',
    'utf8' => '0'
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



