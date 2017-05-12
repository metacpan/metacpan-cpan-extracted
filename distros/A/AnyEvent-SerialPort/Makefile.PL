
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "AnyEvent::Handle subclass for serial ports",
  "AUTHOR" => "Mark Hindess <soft-cpan\@temporalanomaly.com>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyEvent-SerialPort",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::SerialPort",
  "PREREQ_PM" => {
    "AnyEvent::Handle" => 0,
    "Carp" => 0,
    "Device::SerialPort" => 0,
    "Fcntl" => 0,
    "Symbol" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.130171",
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



