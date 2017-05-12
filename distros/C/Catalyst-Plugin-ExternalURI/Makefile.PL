
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Rewrite URLs generated with uri_for",
  "AUTHOR" => "Jose Luis Martinez Torres <jlmartin\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Plugin-ExternalURI",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Plugin::ExternalURI",
  "PREREQ_PM" => {
    "Catalyst::Runtime" => "5.8",
    "Regexp::Common" => 0
  },
  "TEST_REQUIRES" => {
    "Catalyst::Plugin::ConfigLoader" => 0,
    "Catalyst::Plugin::Static::Simple" => 0,
    "Catalyst::Test" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.02",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Catalyst::Plugin::ConfigLoader" => 0,
  "Catalyst::Plugin::Static::Simple" => 0,
  "Catalyst::Runtime" => "5.8",
  "Catalyst::Test" => 0,
  "Regexp::Common" => 0,
  "Test::More" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



