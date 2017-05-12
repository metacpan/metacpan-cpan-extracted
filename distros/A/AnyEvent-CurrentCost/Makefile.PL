
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "AnyEvent module for reading from Current Cost energy meters",
  "AUTHOR" => "Mark Hindess <soft-cpan\@temporalanomaly.com>",
  "BUILD_REQUIRES" => {
    "IO::Pipe" => 0,
    "Test::More" => 0,
    "Test::Requires" => 0,
    "Test::SharedFork" => 0,
    "Test::Warn" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyEvent-CurrentCost",
  "EXE_FILES" => [
    "bin/anyevent-current-cost-reader"
  ],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::CurrentCost",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::Handle" => 0,
    "AnyEvent::SerialPort" => "1.130171",
    "Carp" => 0,
    "Device::CurrentCost" => "1.130190",
    "Device::CurrentCost::Constants" => 0,
    "Getopt::Long" => 0,
    "List::Util" => 0,
    "Pod::Usage" => 0,
    "Sub::Name" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.130190",
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



