
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'split an array into sub-arrays',
  'AUTHOR' => 'Christian Walde <mithaldu@yahoo.de>',
  'BUILD_REQUIRES' => {
    'Cwd' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0',
    'Test::Most' => '0',
    'Test::Simple' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Array-Split',
  'EXE_FILES' => [],
  'LICENSE' => 'unrestricted',
  'NAME' => 'Array::Split',
  'PREREQ_PM' => {
    'List::Util' => '0',
    'POSIX' => '0',
    'Sub::Exporter::Simple' => '0'
  },
  'VERSION' => '1.103261',
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



