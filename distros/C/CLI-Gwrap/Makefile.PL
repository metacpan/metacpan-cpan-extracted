
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "GUI wrapper for command line scripts and programs",
  "AUTHOR" => "Reid Augustin <reid\@hellosix.com>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CLI-Gwrap",
  "EXE_FILES" => [
    "bin/gwrap_ls.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "CLI::Gwrap",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Dancer" => 0,
    "Exporter" => 0,
    "File::Spec" => 0,
    "IO::File" => 0,
    "IPC::Run" => 0,
    "Moo" => "1.000",
    "Moo::Role" => 0,
    "Readonly" => 0,
    "Scalar::Util" => 0,
    "Types::Standard" => 0,
    "Wx" => 0,
    "Wx::App" => 0,
    "Wx::Event" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.030",
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



