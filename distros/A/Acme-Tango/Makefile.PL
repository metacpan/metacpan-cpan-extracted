
use strict;
use warnings;

BEGIN { require v5.8.0; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Turn colours orange',
  'AUTHOR' => 'Peter Sergeant <pete@clueball.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Acme-Tango',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::Tango',
  'PREREQ_PM' => {
    'Convert::Color' => '0.02',
    'Test::More' => '0.01'
  },
  'VERSION' => '0.07',
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



