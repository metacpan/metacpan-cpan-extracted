
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Create a best-effort symlink-based mirror of a directory',
  'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-lntree',
  'EXE_FILES' => [
    'bin/lntree',
    'bin/lntree'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::lntree',
  'PREREQ_PM' => {
    'File::Spec' => '0',
    'File::Spec::Link' => '0',
    'Getopt::Usaginator' => '0',
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



