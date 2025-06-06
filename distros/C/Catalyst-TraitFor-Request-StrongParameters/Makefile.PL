# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "methods for your request object to assist in content negotiation",
  "AUTHOR" => "John Napiorkowski <jjnapiork\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Catalyst-TraitFor-Request-StrongParameters",
  "LICENSE" => "perl",
  "NAME" => "Catalyst::TraitFor::Request::StrongParameters",
  "PREREQ_PM" => {
    "Moose" => "2.1403",
    "Scalar::Util" => "1.55",
    "Storable" => "3.25"
  },
  "TEST_REQUIRES" => {
    "Catalyst::Test" => 0,
    "HTTP::Request::Common" => 0,
    "Test::Most" => "0.34"
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Catalyst::Test" => 0,
  "HTTP::Request::Common" => 0,
  "Moose" => "2.1403",
  "Scalar::Util" => "1.55",
  "Storable" => "3.25",
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
