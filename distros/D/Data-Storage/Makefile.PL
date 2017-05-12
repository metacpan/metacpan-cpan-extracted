
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Base class for storages',
  'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>, Florian Helmberger <fh@univie.ac.at>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Data-Storage',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::Storage',
  'PREREQ_PM' => {
    'Class::Accessor::Complex' => '0',
    'Class::Accessor::Constructor' => '0',
    'Class::Null' => '0',
    'DBI' => '0',
    'Data::Miscellany' => '0',
    'Error' => '0',
    'Error::Hierarchy' => '0',
    'Error::Hierarchy::Internal::DBI' => '0',
    'Error::Hierarchy::Util' => '0',
    'constant' => '0',
    'parent' => '0'
  },
  'VERSION' => '1.102720',
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



