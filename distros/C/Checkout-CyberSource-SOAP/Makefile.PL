
use strict;
use warnings;

use 5.008_001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A Modern Perl interface to CyberSource\'s SOAP API.',
  'AUTHOR' => 'Amiri Barksdale <amiri@arisdottle.net>',
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::Moose' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Checkout-CyberSource-SOAP',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Checkout::CyberSource::SOAP',
  'PREREQ_PM' => {
    'Business::CreditCard' => '0',
    'Moose' => '0',
    'SOAP::Lite' => '0',
    'Time::HiRes' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.07',
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



