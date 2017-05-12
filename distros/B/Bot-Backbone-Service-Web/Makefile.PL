
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Services for Bot::Backbone that do things on the web",
  "AUTHOR" => "Andrew Sterling Hanenkamp <hanenkamp\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bot-Backbone-Service-Web",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Bot::Backbone::Service::Web",
  "PREREQ_PM" => {
    "Bot::Backbone" => 0,
    "Bot::Backbone::Service" => 0,
    "Bot::Backbone::Service::Role::Responder" => 0,
    "Bot::Backbone::Service::Role::Service" => 0,
    "URI::Find" => 0,
    "URI::Title" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.142250",
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



