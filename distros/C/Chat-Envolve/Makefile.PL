
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A Perl API for the Envolve web chat system.',
  'AUTHOR' => 'JT Smith <RIZEN@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Chat-Envolve',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Chat::Envolve',
  'PREREQ_PM' => {
    'Any::Moose' => '0.13',
    'Digest::HMAC_SHA1' => '1.01',
    'Encode' => '0',
    'MIME::Base64' => '3.11',
    'Test::More' => '0'
  },
  'VERSION' => '1.0007',
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



