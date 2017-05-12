
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Template::Alloy wrapper for Dancer',
  'AUTHOR' => 'Daniel Pittman <daniel@rimspace.net>',
  'BUILD_REQUIRES' => {
    'Dancer' => '1.1801',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dancer-Template-Alloy',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dancer::Template::Alloy',
  'PREREQ_PM' => {
    'Dancer' => '1.1801',
    'Dancer::Config' => '0',
    'Dancer::FileUtils' => '0',
    'Dancer::ModuleLoader' => '0',
    'Dancer::Template::Abstract' => '0',
    'Template::Alloy' => '0'
  },
  'VERSION' => '1.02',
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



