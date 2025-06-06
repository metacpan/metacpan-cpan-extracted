# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Catalyst View wrapper for Template::EmbeddedPerl",
  "AUTHOR" => "John Napiorkowski <jjnapiork\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Catalyst-View-EmbeddedPerl",
  "LICENSE" => "perl",
  "NAME" => "Catalyst::View::EmbeddedPerl",
  "PREREQ_PM" => {
    "Catalyst" => "5.90090",
    "Moose" => 0,
    "String::CamelCase" => 0,
    "Template::EmbeddedPerl" => "0.001004"
  },
  "TEST_REQUIRES" => {
    "Catalyst::Test" => 0,
    "HTTP::Request::Common" => 0,
    "Test::Lib" => 0,
    "Test::Most" => "0.34"
  },
  "VERSION" => "0.001002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Catalyst" => "5.90090",
  "Catalyst::Test" => 0,
  "HTTP::Request::Common" => 0,
  "Moose" => 0,
  "String::CamelCase" => 0,
  "Template::EmbeddedPerl" => "0.001004",
  "Test::Lib" => 0,
  "Test::Most" => "0.34"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
