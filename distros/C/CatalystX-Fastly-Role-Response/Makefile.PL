# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.043.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Methods for Fastly intergration to Catalyst",
  "AUTHOR" => "Leo Lapworth",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "CatalystX-Fastly-Role-Response",
  "LICENSE" => "perl",
  "NAME" => "CatalystX::Fastly::Role::Response",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Moose::Role" => 0
  },
  "TEST_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Action::RenderView" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Runtime" => "5.80",
    "Moose" => 0,
    "Test::More" => 0,
    "Test::WWW::Mechanize" => "1.46",
    "Test::WWW::Mechanize::Catalyst" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.07",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Catalyst" => 0,
  "Catalyst::Action::RenderView" => 0,
  "Catalyst::Controller" => 0,
  "Catalyst::Runtime" => "5.80",
  "Moose" => 0,
  "Moose::Role" => 0,
  "Test::More" => 0,
  "Test::WWW::Mechanize" => "1.46",
  "Test::WWW::Mechanize::Catalyst" => 0,
  "namespace::autoclean" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
