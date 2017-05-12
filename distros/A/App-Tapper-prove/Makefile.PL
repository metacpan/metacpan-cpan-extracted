
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - tprove - alternative 'prove' which reports results to Tapper",
  "AUTHOR" => "Steffen Schwigon <ss5\@renormalist.net>",
  "BUILD_REQUIRES" => {
    "Test::Deep" => 0,
    "Test::MockModule" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Tapper-prove",
  "EXE_FILES" => [
    "bin/tprove"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Tapper::prove",
  "PREREQ_PM" => {
    "Archive::Tar" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::Socket::INET" => 0,
    "Sys::Hostname" => 0,
    "TAP::Harness::Archive" => 0,
    "YAML::XS" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.002",
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



