
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a simple HTTP server for developing with CGI::Application",
  "AUTHOR" => "Stevan Little <stevan\@iinteractive.com>, Rob Kinyon <rob.kinyon\@iinteractive.com>, Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CGI-Application-Server",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CGI::Application::Server",
  "PREREQ_PM" => {
    "CGI" => 0,
    "CGI::Application" => "4.21",
    "Carp" => "0.01",
    "HTTP::Response" => 0,
    "HTTP::Server::Simple" => "0.18",
    "HTTP::Server::Simple::CGI" => 0,
    "HTTP::Server::Simple::Static" => "0.02",
    "HTTP::Status" => 0,
    "Scalar::Util" => "1.18",
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "CGI::Application" => 0,
    "CGI::Application::Dispatch" => 0,
    "CGI::Application::Plugin::Redirect" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Exception" => 0,
    "Test::HTTP::Server::Simple" => 0,
    "Test::More" => "0.96",
    "Test::WWW::Mechanize" => 0,
    "lib" => 0
  },
  "VERSION" => "0.063",
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



