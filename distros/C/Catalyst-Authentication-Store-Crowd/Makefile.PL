
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Authentication Store with Crowd REST service",
  "AUTHOR" => "Keerati Thiwanruk <keerati.th\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Controller" => 0,
    "FindBin" => 0,
    "IO::Socket::SSL" => 0,
    "Test::Fake::HTTPD" => 0,
    "Test::More" => 0,
    "Test::TCP" => 0,
    "Test::WWW::Mechanize::Catalyst" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Authentication-Store-Crowd",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Authentication::Store::Crowd",
  "PREREQ_PM" => {
    "Catalyst::Authentication::User" => 0,
    "HTTP::Request" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.04",
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



