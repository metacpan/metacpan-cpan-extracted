
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Acknowledge C<PJAX> requests as browser requests",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "BUILD_REQUIRES" => {
    "Catalyst::Log" => 0,
    "Catalyst::Request" => 0,
    "Catalyst::Request::REST::ForBrowsers" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Headers" => 0,
    "Moose::Meta::Class" => 0,
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-TraitFor-Request-REST-ForBrowsers-AndPJAX",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "Catalyst::TraitFor::Request::REST::ForBrowsers::AndPJAX",
  "PREREQ_PM" => {
    "Catalyst::TraitFor::Request::REST::ForBrowsers" => 0,
    "Moose::Role" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.001",
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



