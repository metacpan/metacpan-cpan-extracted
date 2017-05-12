
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Hack on installed Perl modules',
  'AUTHOR' => 'Peter Shangov <pshangov@yahoo.com>',
  'BUILD_REQUIRES' => {
    'File::Slurp' => '0',
    'File::Spec' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Test::Differences' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-Pmhack',
  'EXE_FILES' => [
    'bin/pmhack'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::Pmhack',
  'PREREQ_PM' => {
    'Carp' => '0',
    'English' => '0',
    'File::Copy' => '0',
    'File::Path' => '2.07',
    'Module::Load' => '0',
    'Module::Locate' => '0',
    'Params::Util' => '0',
    'Perl6::Export::Attrs' => '0',
    'Pod::Usage::CommandLine' => '0',
    'Try::Tiny' => '0'
  },
  'VERSION' => '0.002',
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



