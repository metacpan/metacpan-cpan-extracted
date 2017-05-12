
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A sneakier Scalar::Defer ;-)',
  'AUTHOR' => 'Yuval Kogman',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.89',
    'ok' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Data-Thunk',
  'EXE_FILES' => [],
  'LICENSE' => 'mit',
  'NAME' => 'Data::Thunk',
  'PREREQ_PM' => {
    'B' => '0',
    'Carp' => '0',
    'Check::ISA' => '0',
    'Data::Swap' => '0',
    'Devel::Refcount' => '0',
    'Scalar::Util' => '0',
    'Sub::Exporter' => '0',
    'Try::Tiny' => '0',
    'UNIVERSAL::ref' => '0',
    'namespace::clean' => '0',
    'overload' => '0'
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



