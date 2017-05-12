
use strict;
use warnings;

use 5.014;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "An event loop for wmii (X11 window manager)",
  "AUTHOR" => "David Leadbeater <dgl\@dgl.cx>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-wmiirc",
  "EXE_FILES" => [
    "bin/wmiirc.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::wmiirc",
  "PREREQ_PM" => {
    "Color::Model::RGB" => 0,
    "Const::Fast" => 0,
    "Data::Dump" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "File::Which" => 0,
    "File::stat" => 0,
    "FindBin" => 0,
    "IO::Async::Loop" => 0,
    "IO::Async::Process" => 0,
    "IO::Async::Stream" => 0,
    "IO::Async::Timer::Absolute" => 0,
    "IO::Async::Timer::Countdown" => 0,
    "IPC::Open2" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "POSIX" => 0,
    "Try::Tiny" => 0,
    "URI::Escape" => 0,
    "Unix::Uptime" => 0,
    "User::pwent" => 0,
    "parent" => 0,
    "strict" => 0,
    "strictures" => 1,
    "warnings" => 0
  },
  "VERSION" => "1.000",
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



