
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Curses interface for reading feeds.',
  'AUTHOR' => 'Robin Edwards <robin.ge@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.94',
    'Test::UseAllModules' => '0.12'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-Syndicator',
  'EXE_FILES' => [
    'scripts/syndicator'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::Syndicator',
  'PREREQ_PM' => {
    'Config::Any' => '0.20',
    'Curses::UI' => '0.9607',
    'DBD::SQLite' => '1.29',
    'DateTime' => '0.61',
    'Digest::MD5' => '2.39',
    'HTML::FormatText::WithLinks' => '0.11',
    'IO::All' => '0.41',
    'JSON::Any' => '1.22',
    'KiokuDB' => '0.49',
    'KiokuDB::Backend::DBI' => '1.15',
    'MooseX::ConfigFromFile' => '0.02',
    'MooseX::Declare' => '0.33',
    'MooseX::Getopt' => '0.31',
    'MooseX::Types' => '0.23',
    'MooseX::Types::DateTime' => '0.05',
    'MooseX::Types::URI' => '0.02',
    'Try::Tiny' => '0.06',
    'XML::Feed::Aggregator' => '0.0400'
  },
  'VERSION' => '0.0061',
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



