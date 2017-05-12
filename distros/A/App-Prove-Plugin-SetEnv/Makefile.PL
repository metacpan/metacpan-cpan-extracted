
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a prove plugin to set environment variables",
  "AUTHOR" => "Dagfinn Ilmari Manns\303\245ker <ilmari\@photobox.com>;",
  "BUILD_REQUIRES" => {
    "App::Prove" => 0,
    "Capture::Tiny" => "0.12",
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "ok" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Prove-Plugin-SetEnv",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "App::Prove::Plugin::SetEnv",
  "PREREQ_PM" => {
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
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



