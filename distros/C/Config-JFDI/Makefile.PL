
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Just * Do it: A Catalyst::Plugin::ConfigLoader-style layer over Config::Any',
  'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Config-JFDI',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Config::JFDI',
  'PREREQ_PM' => {
    'Any::Moose' => '0',
    'Carp::Clan::Share' => '0',
    'Clone' => '0',
    'Config::Any' => '0',
    'Config::General' => '0',
    'Data::Visitor' => '0.24',
    'Getopt::Usaginator' => '0',
    'Hash::Merge::Simple' => '0',
    'List::MoreUtils' => '0',
    'Path::Class' => '0',
    'Sub::Install' => '0'
  },
  'VERSION' => '0.065',
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



