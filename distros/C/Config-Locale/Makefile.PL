
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Load and merge locale-specific configuration files.",
  "AUTHOR" => "Aran Deltac <bluefeet\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Simple" => "0.94"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Config-Locale",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Config::Locale",
  "PREREQ_PM" => {
    "Algorithm::Loops" => "1.031",
    "Carp" => 0,
    "Config::Any" => "0.04",
    "Hash::Merge" => "0.12",
    "List::MoreUtils" => 0,
    "Path::Class" => 0,
    "Scalar::Util" => 0
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



