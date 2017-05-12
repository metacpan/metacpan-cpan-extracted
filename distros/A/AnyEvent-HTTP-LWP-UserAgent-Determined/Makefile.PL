
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a virtual browser that retries errors with AnyEvent",
  "AUTHOR" => "Yasutaka ATARASHI <yakex\@cpan.org>",
  "BUILD_REQUIRES" => {
    "HTTP::Server::Simple::CGI" => 0,
    "Test::TCP" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyEvent-HTTP-LWP-UserAgent-Determined",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::HTTP::LWP::UserAgent::Determined",
  "PREREQ_PM" => {
    "AnyEvent::HTTP::LWP::UserAgent" => "0.08",
    "LWP" => 0,
    "LWP::UserAgent::Determined" => 0
  },
  "VERSION" => "v0.05.1.06",
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



