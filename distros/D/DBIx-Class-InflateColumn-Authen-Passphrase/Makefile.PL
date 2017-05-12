
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Inflate/deflate columns to Authen::Passphrase instances',
  'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>',
  'BUILD_REQUIRES' => {
    'Authen::Passphrase::BlowfishCrypt' => '0',
    'Authen::Passphrase::SaltedDigest' => '0',
    'DBIx::Class::Core' => '0',
    'DBIx::Class::Schema' => '0',
    'FindBin' => '0',
    'SQL::Translator' => '0',
    'Test::More' => '0.89'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'DBIx-Class-InflateColumn-Authen-Passphrase',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'DBIx::Class::InflateColumn::Authen::Passphrase',
  'PREREQ_PM' => {
    'Authen::Passphrase' => '0',
    'DBIx::Class' => '0',
    'parent' => '0'
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



