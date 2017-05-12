
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'gather smoking statistics from minismokebox',
  'AUTHOR' => 'Chris Williams <chris@bingosnet.co.uk>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.47'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'App-SmokeBox-Mini-Plugin-Stats',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'App::SmokeBox::Mini::Plugin::Stats',
  'PREREQ_PM' => {
    'App::SmokeBox::Mini' => '0.32',
    'App::SmokeBox::Mini::Plugin' => '0.32',
    'DBD::SQLite' => '1.31',
    'DBI' => '1.614',
    'POE' => '1.293',
    'POE::Component::EasyDBI' => '1.23',
    'Time::HiRes' => '0'
  },
  'VERSION' => '0.10',
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



