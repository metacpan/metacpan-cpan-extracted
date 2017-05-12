
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Declare RESTful API for CGI::Application",
  "AUTHOR" => "Aku Kauste <aku\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CGI-Application-Plugin-DeclareREST",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CGI::Application::Plugin::DeclareREST",
  "PREREQ_PM" => {
    "CGI::Application" => "4.50",
    "Exporter" => 0,
    "REST::Utils" => 0,
    "Routes::Tiny" => "0.11",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "CGI::Application" => 0,
    "CGI::Application::PSGI" => 0,
    "CGI::PSGI" => 0,
    "Plack::Builder" => 0,
    "Test::More" => 0,
    "Test::WWW::Mechanize::PSGI" => 0,
    "base" => 0
  },
  "VERSION" => "0.01",
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



