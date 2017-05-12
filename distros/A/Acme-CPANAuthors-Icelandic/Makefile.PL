
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'We are Icelandic CPAN authors',
  'AUTHOR' => 'Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.47'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Acme-CPANAuthors-Icelandic',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::CPANAuthors::Icelandic',
  'PREREQ_PM' => {
    'Acme::CPANAuthors' => '0',
    'Acme::CPANAuthors::Register' => '0'
  },
  'VERSION' => '0.04',
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



