
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A simple grep-like filter that highlights chosen words or lines rather than removing non-filtered lines.",
  "AUTHOR" => "Alex Balhatchet <kaoru\@slackwise.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-highlight",
  "EXE_FILES" => [
    "bin/highlight"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::highlight",
  "PREREQ_PM" => {
    "App::Cmd::Simple" => "0.309",
    "ExtUtils::MakeMaker" => "6.55_02",
    "Getopt::Long" => "2.39",
    "Getopt::Long::Descriptive" => "0.085",
    "Module::Load" => "0.18",
    "Try::Tiny" => "0.09"
  },
  "TEST_REQUIRES" => {
    "App::Cmd::Tester" => "0.309",
    "Test::More" => "0.92",
    "Test::Without::Module" => "0.17"
  },
  "VERSION" => "0.14",
  "test" => {
    "TESTS" => "t/*.t"
  }
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



