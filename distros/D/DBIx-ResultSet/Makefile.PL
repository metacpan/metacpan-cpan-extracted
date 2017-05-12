
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Lightweight SQL query building and execution.',
  'AUTHOR' => 'Aran Deltac <bluefeet@gmail.com>',
  'BUILD_REQUIRES' => {
    'DBD::SQLite' => '1.29',
    'DateTime' => '0.55',
    'DateTime::Format::SQLite' => '0.11',
    'Test::Exception' => '0.29',
    'Test::Simple' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'DBIx-ResultSet',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'DBIx::ResultSet',
  'PREREQ_PM' => {
    'Clone' => '0.31',
    'DBIx::Connector' => '0.33',
    'Data::Page' => '2.02',
    'List::MoreUtils' => '0.22',
    'Module::Load' => '0.18',
    'Moose' => '1.01',
    'MooseX::Types' => '0.21',
    'SQL::Abstract' => '1.65',
    'SQL::Abstract::Limit' => '0.141',
    'namespace::autoclean' => '0.09'
  },
  'VERSION' => '0.17',
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



