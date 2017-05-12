use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
  'ABSTRACT' => 'Catalyst SQL::Library Model',
  'AUTHOR' => 'Alex Pavlovic <alex.pavlovic@taskforce-1.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Catalyst-Model-DBI-SQL-Library',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::Model::DBI::SQL::Library',
  'PREREQ_PM' => {
    'DBI' => 0,
    'SQL::Library' => 0,
    'Catalyst' => 0,
    'Catalyst::Model::DBI' => 0,
    'strict' => 0,
    'warnings' => 0
  },
  'TEST_REQUIRES' => {
    'Catalyst' => 0,
    'Catalyst::Controller' => 0,
    'Catalyst::ScriptRunner' => 0,
    'Catalyst::Test' => 0,
    'Catalyst::Model::DBI' => 0,
    'DBI' => 0,
    'SQL::Library' => 0,    
    'FindBin' => 0,
    'Test::More' => 0,
    'Test::Pod' => '1.14',
    'Test::Pod::Coverage' => '1.04',
    'base' => 0,
    'namespace::autoclean' => 0,
    'ok' => 0
  },
  'VERSION_FROM' => 'lib/Catalyst/Model/DBI/SQL/Library.pm',
  'test' => {
    'TESTS' => "t/*.t"
  }
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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