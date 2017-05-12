
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A processor that filters parts of data structures',
  'AUTHOR' => 'Alexei Znamensky <russoz@cpan.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'List::MoreUtils' => '0',
    'Test::More' => '0.88',
    'Test::UseAllModules' => '0',
    'perl' => '5.006'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'DataFlow-Proc-DPath',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'DataFlow::Proc::DPath',
  'PREREQ_PM' => {
    'Data::DPath' => '0',
    'DataFlow' => '1.112100',
    'DataFlow::Proc' => '0',
    'Moose' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '1.112100',
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



