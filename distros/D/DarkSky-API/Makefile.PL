
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "The Dark Sky API lets you query for short-term \nprecipitation forecast data at geographical points inside\nthe United States.",
  "AUTHOR" => "Martin-Louis Bright <mlbright\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Data::Dumper" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DarkSky-API",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DarkSky::API",
  "PREREQ_PM" => {
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "Mojo::UserAgent" => 0,
    "Moose" => 0
  },
  "VERSION" => "0.05",
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



