
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'java.util.ArrayList for perl',
  'AUTHOR' => 'Alex J. G. Burzyński <ajgb@cpan.org>',
  'BUILD_REQUIRES' => {
    'Module::Build' => '0.3601',
    'Scalar::Util' => '1.21',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::NoWarnings' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Data-ArrayList',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::ArrayList',
  'PREREQ_PM' => {
    'Data::Clone' => '0.001',
    'Moose' => '1.15'
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



