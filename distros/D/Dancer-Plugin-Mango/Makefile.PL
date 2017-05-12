
use strict;
use warnings;



use ExtUtils::MakeMaker 6.96;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Dancer plugin for MongoDB - Using Mango',
  'AUTHOR' => 'Tyler Hardison <tyler@seraph-net.net>',
  'MIN_PERL_VERSION' => '5.6.0',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.96'
  },
  'DISTNAME' => 'Dancer-Plugin-Mango',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dancer::Plugin::Mango',
  'PREREQ_PM' => {
    'Dancer::Plugin' => '0',
    'Mango' => '0.30'
  },
  'VERSION' => '0.41',
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
