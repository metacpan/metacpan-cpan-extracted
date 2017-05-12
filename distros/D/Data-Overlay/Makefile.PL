
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'merge/overlay data with composable changes',
  'AUTHOR' => 'Brad Bowman <cpan@bereft.net>',
  'BUILD_REQUIRES' => {
    'Test::Deep' => '0',
    'Test::More' => '0.87_01'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Data-Overlay',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::Overlay',
  'PREREQ_PM' => {
    'List::MoreUtils' => '0',
    'Sub::Name' => '0'
  },
  'VERSION' => '0.54',
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



