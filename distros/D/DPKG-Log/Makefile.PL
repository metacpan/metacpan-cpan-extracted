
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Parse the dpkg log',
  'AUTHOR' => 'Patrick Schoenfeld <schoenfeld@debian.org>',
  'BUILD_REQUIRES' => {
    'Benchmark' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'DPKG-Log',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'DPKG::Log',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Data::Dumper' => '0',
    'DateTime::Format::Strptime' => '0',
    'DateTime::TimeZone' => '0',
    'Dpkg::Version' => '0',
    'Exporter' => '0',
    'Params::Validate' => '0',
    'overload' => '0'
  },
  'VERSION' => '1.20',
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



