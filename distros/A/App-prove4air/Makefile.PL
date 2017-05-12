
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Test ActionScript (.as) with prove, Adobe Air, and tap4air',
  'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-prove4air',
  'EXE_FILES' => [
    'bin/prove4air',
    'bin/prove4air'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::prove4air',
  'PREREQ_PM' => {
    'File::Copy' => '0',
    'Getopt::Long' => '0',
    'IPC::System::Simple' => '0',
    'Path::Class' => '0'
  },
  'VERSION' => '0.0013',
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



