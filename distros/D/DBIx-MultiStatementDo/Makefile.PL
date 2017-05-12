
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Multiple SQL statements in a single do() call with any DBI driver',
  'AUTHOR' => 'Emanuele Zeppieri <emazep@cpan.org>',
  'BUILD_REQUIRES' => {
    'DBD::SQLite' => '0',
    'DBI' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::Exception' => '0.27',
    'Test::More' => '0.7'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'DBIx-MultiStatementDo',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'DBIx::MultiStatementDo',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Moose' => '0',
    'SQL::SplitStatement' => '1.00009'
  },
  'VERSION' => '1.00009',
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



