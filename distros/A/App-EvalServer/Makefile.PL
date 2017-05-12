
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Evaluate arbitrary code in a safe environment',
  'AUTHOR' => 'Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-EvalServer',
  'EXE_FILES' => [
    'bin/evalserver'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::EvalServer',
  'PREREQ_PM' => {
    'BSD::Resource' => '0',
    'File::Temp' => '0.22',
    'POE' => '1.291',
    'POE::Filter::JSON' => '0',
    'POE::Filter::Reference' => '0',
    'POE::Filter::Stream' => '0',
    'POE::Session' => '0',
    'POE::Wheel::ReadWrite' => '0',
    'POE::Wheel::Run' => '0',
    'POE::Wheel::SocketFactory' => '0',
    'Proc::Daemon' => '0'
  },
  'VERSION' => '0.08',
  'test' => {
    'TESTS' => 't/*.t t/langs/*.t'
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



