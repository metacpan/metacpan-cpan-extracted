
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "trim chatty command outputs",
  "AUTHOR" => "Gaal Yahas <gaal\@forum2.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Prolix",
  "EXE_FILES" => [
    "bin/prolix"
  ],
  "LICENSE" => "mit",
  "NAME" => "App::Prolix",
  "PREREQ_PM" => {
    "Data::Munge" => 0,
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "IPC::Run" => 0,
    "JSON" => "2.0",
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "MooseX::ConfigFromFile" => 0,
    "MooseX::Getopt" => "0.39",
    "String::ShellQuote" => 0,
    "Term::ReadKey" => 0,
    "Term::ReadLine" => 0,
    "Text::Balanced" => 0,
    "Try::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.03",
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



