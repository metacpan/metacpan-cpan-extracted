
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Build types from Data::Rx schema (experimental)',
  'AUTHOR' => 'Andrew Sterling Hanenkamp <hanenkamp@cpan.org>',
  'BUILD_REQUIRES' => {
    'Data::Rx' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Data-Rx-TypeBundle-Rx',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::Rx::TypeBundle::Rx',
  'PREREQ_PM' => {
    'Data::Rx::TypeBundle' => '0'
  },
  'VERSION' => '0.103520',
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



