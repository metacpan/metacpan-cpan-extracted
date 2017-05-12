use strict;
use warnings;

use ExtUtils::MakeMaker 6.31;

my %WriteMakefileArgs = (
  'ABSTRACT' => 'Integrate the AreYouAHuman.com CAPTCHA-alterantive human verification into your Perl application',
  'AUTHOR' => 'Jonathan Brown <jonathan@areyouahuman.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Captcha-AreYouAHuman',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Captcha::AreYouAHuman',
  'PREREQ_PM' => {
    'LWP::UserAgent' => '5.834',
    'URI::Escape'    => '3.29',
    'JSON'           => '2.17'
  },
  'VERSION' => '0.00003',
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

