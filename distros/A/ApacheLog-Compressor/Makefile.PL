
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Convert Apache/CLF data to binary format",
  "AUTHOR" => "Tom Molesworth <cpan\@entitymodel.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "ApacheLog-Compressor",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "ApacheLog::Compressor",
  "PREREQ_PM" => {
    "Date::Parse" => 0,
    "DateTime" => 0,
    "Encode" => 0,
    "List::Util" => 0,
    "Socket" => 0,
    "URI" => 0,
    "URI::Escape" => 0
  },
  "VERSION" => "0.005",
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



