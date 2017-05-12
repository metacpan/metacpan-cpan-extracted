
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "authenticate people and read books!",
  "AUTHOR" => "Diego Kuperman <diego\@freekeylabs.com>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Runtime" => "5.80",
    "FindBin" => 0,
    "Moose" => 0,
    "Test::More" => 0,
    "Test::WWW::Mechanize::Catalyst" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-TraitFor-Controller-reCAPTCHA",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::TraitFor::Controller::reCAPTCHA",
  "PREREQ_PM" => {
    "Captcha::reCAPTCHA" => 0,
    "Carp" => 0,
    "Moose::Role" => 0,
    "MooseX::MethodAttributes::Role" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "1.122510",
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



