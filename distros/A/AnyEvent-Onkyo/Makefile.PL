
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "AnyEvent module for controlling Onkyo/Integra AV equipment",
  "AUTHOR" => "Mark Hindess <soft-cpan\@temporalanomaly.com>",
  "BUILD_REQUIRES" => {
    "IO::Socket::INET" => 0,
    "Socket" => 0,
    "Test::More" => 0,
    "Test::Requires" => 0,
    "Test::SharedFork" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyEvent-Onkyo",
  "EXE_FILES" => [
    "bin/onkyo-anyevent"
  ],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::Onkyo",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::Handle" => 0,
    "AnyEvent::SerialPort" => 0,
    "Carp" => 0,
    "Device::Onkyo" => 0,
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "Scalar::Util" => 0,
    "Sub::Name" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.130220",
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



