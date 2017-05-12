
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl module info command line.',
  'AUTHOR' => 'Thiago Rondon <thiago@nsms.com.br>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'App-pmodinfo',
  'EXE_FILES' => [
    'bin/pmodinfo',
    'bin/pmodinfo'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::pmodinfo',
  'PREREQ_PM' => {
    'Config' => '0',
    'DateTime' => '0',
    'ExtUtils::Installed' => '0',
    'File::Which' => '0',
    'File::stat' => '0',
    'FindBin' => '0',
    'Getopt::Long' => '0',
    'LWP::Simple' => '0',
    'Module::CoreList' => '0',
    'Module::Metadata' => '0',
    'Parse::CPAN::Meta' => '0'
  },
  'VERSION' => '0.10',
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



