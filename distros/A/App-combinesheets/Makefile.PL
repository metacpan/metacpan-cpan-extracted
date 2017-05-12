
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "command-line tool merging CSV and TSV spreadsheets",
  "AUTHOR" => "Martin Senger <martin.senger\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-combinesheets",
  "EXE_FILES" => [
    "bin/combinesheets"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::combinesheets",
  "PREREQ_PM" => {
    "Algorithm::Loops" => 0,
    "App::Cmd::Simple" => 0,
    "Data::Dumper" => 0,
    "File::BOM" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "File::Which" => 0,
    "IO::CaptureOutput" => 0,
    "Pod::Find" => 0,
    "Pod::Usage" => 0,
    "Text::CSV::Simple" => 0,
    "Text::CSV_XS" => 0,
    "autouse" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Cwd" => 0,
    "File::Basename" => 0,
    "File::Find" => 0,
    "FindBin" => 0,
    "IO::CaptureOutput" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.2.14",
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



