
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Unit Generator Based Sound Synthesizer",
  "AUTHOR" => "Brock Wilcox <awwaiid\@thelackthereof.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Audio-NoiseGen",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Audio::NoiseGen",
  "PREREQ_PM" => {
    "Audio::PortAudio" => 0,
    "Exporter" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "overload" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => ""
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



