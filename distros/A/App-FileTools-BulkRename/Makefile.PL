
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "bulk rename - a fork of rename.",
  "AUTHOR" => "Stirling Westrup <swestrup\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-FileTools-BulkRename",
  "EXE_FILES" => [
    "bin/brn"
  ],
  "LICENSE" => "gpl",
  "NAME" => "App::FileTools::BulkRename",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Clipboard" => 0,
    "Config::IniFiles" => 0,
    "Contextual::Return" => 0,
    "Data::Dump" => 0,
    "Data::Dumper" => 0,
    "Encode" => 0,
    "Exporter" => 0,
    "File::Slurp" => 0,
    "FindBin" => 0,
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "IO::Interactive" => 0,
    "Lingua::EN::Titlecase" => 0,
    "List::Util" => 0,
    "Pod::Text::Termcap" => 0,
    "Pod::Usage" => 0,
    "Scalar::Util" => 0,
    "Text::Autoformat" => 0,
    "Text::ParseWords" => 0,
    "enum" => 0,
    "feature" => 0,
    "open" => 0,
    "strict" => 0,
    "subs" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.07",
  "test" => {
    "TESTS" => "t/*.t t/usercommands/*.t"
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



