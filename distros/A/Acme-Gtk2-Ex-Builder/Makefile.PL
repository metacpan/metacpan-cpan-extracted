
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Funny Gtk2 Interface Design Module',
  'AUTHOR' => 'Keedi Kim - 김도형 <keedi@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Acme-Gtk2-Ex-Builder',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::Gtk2::Ex::Builder',
  'PREREQ_PM' => {
    'Exporter' => '0'
  },
  'VERSION' => '0.008',
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



