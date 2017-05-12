
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A command line tool for launching a POE::Component::Server::IRC instance',
  'AUTHOR' => 'Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.47',
    'Test::Script' => '1.07'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'App-Pocosi',
  'EXE_FILES' => [
    'bin/pocosi'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::Pocosi',
  'PREREQ_PM' => {
    'Class::Load' => '0.06',
    'Data::Dump' => '0',
    'IO::WrapOutput' => '0.02',
    'IRC::Utils' => '0.10',
    'JSON::XS' => '0',
    'Module::Pluggable' => '0',
    'POE' => '1.310',
    'POE::Component::Server::IRC' => '1.48',
    'Proc::Daemon' => '0.02',
    'Term::ANSIColor' => '0',
    'Term::Cap' => '1.10',
    'Term::ReadKey' => '2.21',
    'YAML::XS' => '0'
  },
  'VERSION' => '0.03',
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



