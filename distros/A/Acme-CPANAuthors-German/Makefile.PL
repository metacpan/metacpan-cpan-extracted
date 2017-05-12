
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'We are German CPAN authors',
  'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>',
  'BUILD_REQUIRES' => {
    'Acme::CPANAuthors' => '0',
    'Acme::CPANAuthors::Austrian' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Acme-CPANAuthors-German',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::CPANAuthors::German',
  'PREREQ_PM' => {
    'Acme::CPANAuthors::Register' => '0',
    'utf8' => '0'
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



