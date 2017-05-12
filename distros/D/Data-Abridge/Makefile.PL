
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Simplify data structures for naive serialization.',
  'AUTHOR' => 'Mark Swayne <daotoad@cpan.org>',
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'Storable' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Data-Abridge',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::Abridge',
  'PREREQ_PM' => {
    'B' => '0',
    'Carp' => '0',
    'Exporter' => '0',
    'Scalar::Util' => '0',
    'constant' => '0',
    'overload' => '0'
  },
  'VERSION' => '0.03.01',
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



