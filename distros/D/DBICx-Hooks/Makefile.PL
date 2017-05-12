
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Provide hooks into DBIx::Class create()/update()/delete()',
  'AUTHOR' => 'Pedro Melo <melo@simplicidade.org>',
  'BUILD_REQUIRES' => {
    'Test::Deep' => '0',
    'Test::Fatal' => '0',
    'Test::MockObject' => '0',
    'Test::More' => '0.92'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'DBICx-Hooks',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'DBICx::Hooks',
  'PREREQ_PM' => {
    'DBIx::Class' => '0',
    'Exporter' => '0',
    'SQL::Translator' => '0.11006',
    'Scalar::Util' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.003',
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



