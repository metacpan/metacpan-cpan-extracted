
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Mount any Plack application to a URL root",
  "AUTHOR" => "John Napiorkowski <jjnapiork\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Catalyst" => "5.90001",
    "Catalyst::Test" => 0,
    "FindBin" => 0,
    "HTTP::Request::Common" => 0,
    "Moose" => 0,
    "Plack::App::File" => 0,
    "Plack::App::URLMap" => 0,
    "Plack::Component" => 0,
    "Plack::Util" => 0,
    "Scalar::Util" => 0,
    "Test::Most" => "0.25"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Plugin-URLMap",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Plugin::URLMap",
  "PREREQ_PM" => {
    "Catalyst::Utils" => 0,
    "Moose::Role" => 0,
    "Text::SimpleTable" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.002",
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



