
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "command line file finding utility that understands TPath",
  "AUTHOR" => "David F. Houghton <dfhoughton\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-tfind",
  "EXE_FILES" => [
    "bin/tfind",
    "bin/tfind"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::tfind",
  "PREREQ_PM" => {
    "Cwd" => 0,
    "Getopt::Long::Descriptive" => 0,
    "Pod::Usage" => 0,
    "TPath" => "0.020",
    "TPath::Forester::File" => "0.002",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "IPC::Run" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "0.001",
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



