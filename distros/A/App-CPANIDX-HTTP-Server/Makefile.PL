
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "HTTP::Server::Simple based server for CPANIDX",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-CPANIDX-HTTP-Server",
  "EXE_FILES" => [
    "bin/cpanidx_httpserver"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::CPANIDX::HTTP::Server",
  "PREREQ_PM" => {
    "App::CPANIDX" => "0.28",
    "Config::Tiny" => "2.12",
    "HTTP::Server::Simple" => "0.43",
    "HTTP::Server::Simple::CGI" => 0
  },
  "VERSION" => "0.08",
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



