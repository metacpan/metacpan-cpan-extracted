
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'corrects PERL to Perl in strings automatically',
  'AUTHOR' => 'chromatic',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.98'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Acme-PERL-Autocorrect',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Acme::PERL::Autocorrect',
  'PREREQ_PM' => {
    'optimizer' => '0'
  },
  'VERSION' => '1.20110629',
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



