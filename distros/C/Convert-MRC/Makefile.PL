
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "CONVERT MRC TO TBX-BASIC",
  "AUTHOR" => "Nathan Rasmussen, Nathan Glenn <garfieldnate\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Convert-MRC",
  "EXE_FILES" => [
    "bin/mrc2tbx"
  ],
  "LICENSE" => "perl",
  "NAME" => "Convert::MRC",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "English" => 0,
    "Exporter" => 0,
    "Log::Message::Simple" => 0,
    "base" => 0,
    "open" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Section::Simple" => 0,
    "File::Find" => 0,
    "File::Slurp" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "File::Touch" => 0,
    "FindBin" => 0,
    "Test::Base" => 0,
    "Test::Base::Filter" => 0,
    "Test::LongString" => 0,
    "Test::More" => "0.96",
    "Test::XML" => 0,
    "autodie" => 0
  },
  "VERSION" => "4.03",
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



