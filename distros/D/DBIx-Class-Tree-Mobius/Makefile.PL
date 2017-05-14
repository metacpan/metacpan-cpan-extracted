
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Manage trees of data using the Möbius encoding (nested intervals with continued fraction)',
  'AUTHOR' => 'Valentin D Guillois <vdg@polygonism.net>',
  'BUILD_REQUIRES' => {
    'SQL::Translator' => '0.11006',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'DBIx-Class-Tree-Mobius',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'DBIx::Class::Tree::Mobius',
  'PREREQ_PM' => {
    'Carp' => '0',
    'DBIx::Class' => '0',
    'Digest' => '0',
    'ExtUtils::MakeMaker' => '0',
    'Math::BigFloat' => '0'
  },
  'VERSION' => '0.212',
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



