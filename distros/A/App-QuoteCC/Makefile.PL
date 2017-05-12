
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Take a quote file and emit a standalone program that spews a random quote',
  'AUTHOR' => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
  'BUILD_REQUIRES' => {
    'Encode' => '0',
    'File::Find' => '0',
    'File::Slurp' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-QuoteCC',
  'EXE_FILES' => [
    'bin/quotecc'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::QuoteCC',
  'PREREQ_PM' => {
    'Data::Section' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'MooseX::Getopt::Dashes' => '0',
    'Template' => '0',
    'YAML::Syck' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => '0.10',
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



