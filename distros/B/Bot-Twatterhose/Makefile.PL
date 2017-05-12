
use strict;
use warnings;

 BEGIN { require 5.010; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Consume the Twitter firehose and babble to Twitter with L<Hailo>',
  'AUTHOR' => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Bot-Twatterhose',
  'EXE_FILES' => [
    'bin/twatterhose'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Bot::Twatterhose',
  'PREREQ_PM' => {
    'Any::Moose' => '0',
    'Encode' => '0',
    'Hailo' => '0',
    'JSON' => '0',
    'Mouse' => '0.50',
    'MouseX::Getopt' => '0.2601',
    'MouseX::Types' => '0.05',
    'Net::Twitter::Lite' => '0',
    'Scalar::Util' => '0',
    'Sys::Prctl' => '0',
    'autodie' => '0',
    'namespace::clean' => '0',
    'open' => '0'
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



