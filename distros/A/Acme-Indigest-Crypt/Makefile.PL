
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Acme::Indigest::Crypt',
  'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Acme-Indigest-Crypt',
  'EXE_FILES' => [
    'bin/indigestable-crypt',
    'bin/indigestable-crypt'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::Indigest::Crypt',
  'PREREQ_PM' => {
    'Crypt::Passwd::XS' => '0',
    'Term::ReadKey' => '0'
  },
  'VERSION' => '0.0011',
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



