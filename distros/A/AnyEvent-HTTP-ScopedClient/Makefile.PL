
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "AnyEvent::HTTP wrapper",
  "AUTHOR" => "Hyungsuk Hong <hshong\@perl.kr>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyEvent-HTTP-ScopedClient",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::HTTP::ScopedClient",
  "PREREQ_PM" => {
    "AnyEvent::HTTP" => 0,
    "Encode" => 0,
    "HTTP::Request" => 0,
    "MIME::Base64" => 0,
    "Moose" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "URI::QueryParam" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "AnyEvent" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0.5",
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



