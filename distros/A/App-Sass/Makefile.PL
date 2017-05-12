
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "sass command-line tool modeled after the ruby's version",
  "AUTHOR" => "William Wolf <throughnothing\@gmail.com>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Sass",
  "EXE_FILES" => [
    "bin/sassp"
  ],
  "LICENSE" => "unrestricted",
  "NAME" => "App::Sass",
  "PREREQ_PM" => {
    "Data::Dump" => 0,
    "File::Slurp" => 0,
    "Filesys::Notify::Simple" => 0,
    "Getopt::Long" => 0,
    "Path::Class" => 0,
    "Pod::Usage" => 0,
    "Text::Sass" => 0,
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



