
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple workflow manager",
  "AUTHOR" => "Heikki Lehvaslaiho, KAUST (King Abdullah University of Science and Technology).",
  "BUILD_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "App-Pipeline-Simple",
  "EXE_FILES" => [
    "bin/spipe"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Pipeline::Simple",
  "PREREQ_PM" => {
    "Carp" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "Getopt::Long" => 0,
    "GraphViz" => 0,
    "Log::Log4perl" => 0,
    "YAML::Syck" => 0,
    "autodie" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.9.1",
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



