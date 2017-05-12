
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'extract probable dates from strings *with surprises*',
  'AUTHOR' => 'Stephen R. Scaffidi <sscaffidi@cpan.org>',
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Date-Extract-Surprise',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Date::Extract::Surprise',
  'PREREQ_PM' => {
    'Carp' => '0',
    'DateTime::Format::Flexible' => '0.10',
    'Exporter::Easy' => '0',
    'Scalar::Util' => '0'
  },
  'VERSION' => '0.006',
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



