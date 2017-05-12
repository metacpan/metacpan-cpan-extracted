
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Manage (delete/undelete) your PAUSE files',
  'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-PAUSE-cleanup',
  'EXE_FILES' => [
    'bin/pause-cleanup',
    'bin/pause-cleanup'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::PAUSE::cleanup',
  'PREREQ_PM' => {
    'Config::Identity' => '0.0015',
    'Crypt::SSLeay' => '0',
    'Getopt::Long' => '0',
    'Getopt::Usaginator' => '0',
    'Term::EditorEdit' => '0',
    'WWW::Mechanize' => '0'
  },
  'VERSION' => '0.0012',
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



