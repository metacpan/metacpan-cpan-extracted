
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'load TOC (Table of Contents) jQuery plugin.',
  'AUTHOR' => 'Konstantin Kapitanov <perlovik@gmail.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Bootylicious-Plugin-TocJquery',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Bootylicious::Plugin::TocJquery',
  'PREREQ_PM' => {
    'Bootylicious::Plugin::AjaxLibLoader' => '0.05',
    'Mojo' => '0.999910'
  },
  'VERSION' => '0.06',
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



