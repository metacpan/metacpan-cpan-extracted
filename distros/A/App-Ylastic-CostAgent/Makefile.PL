
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl port of the Ylastic Cost Agent for Amazon Web Services',
  'AUTHOR' => 'David Golden <dagolden@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'Test::Fatal' => '0',
    'Test::More' => '0.88',
    'Test::Warn' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-Ylastic-CostAgent',
  'EXE_FILES' => [
    'bin/ylastic-costagent'
  ],
  'LICENSE' => 'apache',
  'NAME' => 'App::Ylastic::CostAgent',
  'PREREQ_PM' => {
    'Archive::Zip' => '0',
    'Carp' => '0',
    'Config::Tiny' => '0',
    'File::Basename' => '0',
    'File::Spec::Functions' => '0',
    'File::Temp' => '0',
    'Getopt::Lucid' => '0',
    'IO::Socket::SSL' => '0',
    'Log::Dispatchouli' => '2',
    'Mozilla::CA' => '0',
    'Object::Tiny' => '0',
    'Pod::Usage' => '0',
    'Time::Piece' => '0',
    'Time::Piece::Month' => '0',
    'WWW::Mechanize' => '0',
    'autodie' => '2.00',
    'utf8' => '0'
  },
  'VERSION' => '0.006',
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



