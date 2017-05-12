
use strict;
use warnings;

use 5.008008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "DBIx::Class based session engine for Dancer",
  "AUTHOR" => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dancer2-Session-DBIC",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer2::Session::DBIC",
  "PREREQ_PM" => {
    "DBIx::Class" => 0,
    "DBICx::Sugar" => 0,
    "Dancer2" => "0.14",
    "Try::Tiny" => "0.01",
    "Scalar::Util" => 0,
    "Module::Runtime" => 0,
    "JSON::MaybeXS" => 0,
    "namespace::clean" => 0,
  },
  "TEST_REQUIRES" => {
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.63",
    "DBICx::TestDatabase" => 0,
    "DBIx::Class::TimeStamp" => 0,
  },
  "VERSION_FROM" => 'lib/Dancer2/Session/DBIC.pm',
  "test" => {
    "TESTS" => join( ' ', ( glob('t/*.t'), glob('t/*/*.t') ) )
  },
  META_MERGE        => {
        resources => {
            repository => 'https://github.com/interchange/Dancer2-Session-DBIC.git',
            bugtracker => 'https://github.com/interchange/Dancer2-Session-DBIC/issues',
            IRC => 'irc://irc.perl.org/#dancer',
        },
   },
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



