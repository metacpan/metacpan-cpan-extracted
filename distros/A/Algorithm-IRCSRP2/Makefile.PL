
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'IRC channel encryption algorithm',
  'AUTHOR' => 'Adam Flott <adam@npjh.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Algorithm-IRCSRP2',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Algorithm::IRCSRP2',
  'PREREQ_PM' => {
    'Crypt::OpenSSL::AES' => '0',
    'Crypt::URandom' => '0',
    'Digest::SHA' => '0',
    'MIME::Base64' => '0',
    'Math::BigInt::GMP' => '0',
    'Moose' => '0',
    'Sub::Exporter' => '0'
  },
  'VERSION' => '0.501',
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



