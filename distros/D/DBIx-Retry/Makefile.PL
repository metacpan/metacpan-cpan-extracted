
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "DBIx::Connector with the ability to retry the run method for a specified amount of time.\r",
  "AUTHOR" => "Hartmut Behrens <hartmut.behrens\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::MockModule" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-Retry",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Retry",
  "PREREQ_PM" => {
    "DBIx::Connector" => 0,
    "Moo" => 0,
    "Try::Tiny" => 0,
    "parent" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
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



