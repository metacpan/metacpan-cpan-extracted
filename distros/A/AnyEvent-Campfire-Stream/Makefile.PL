
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Receive Campfire streaming API in an event loop",
  "AUTHOR" => "Hyungsuk Hong <hshong\@perl.kr>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "strict" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyEvent-Campfire-Stream",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::Campfire::Stream",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::HTTP" => 0,
    "JSON::XS" => 0,
    "MIME::Base64" => 0,
    "Moose" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.0.3",
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



