
use strict;
use warnings;

BEGIN { require 5.008_000; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a Plack middleware to be used for Dancer',
  'AUTHOR' => 'Flavio Poletti <polettix@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dancer-Middleware-Rebase',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Dancer::Middleware::Rebase',
  'PREREQ_PM' => {
    'Plack::Middleware' => '0',
    'URI' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.8.0',
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



