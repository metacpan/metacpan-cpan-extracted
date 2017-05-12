
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Converts fuzzy time into local time",
  "AUTHOR" => "Traian Nedelea <tron\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-epoch",
  "EXE_FILES" => [
    "bin/epoch"
  ],
  "LICENSE" => "unrestricted",
  "NAME" => "App::epoch",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "FindBin" => 0,
    "Time::Format" => 0,
    "Time::ParseDate" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.001",
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



