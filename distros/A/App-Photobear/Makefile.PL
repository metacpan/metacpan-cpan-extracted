# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.024;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Photobear API client",
  "AUTHOR" => "Andrea Telatin <proch\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-Photobear",
  "EXE_FILES" => [
    "bin/curly",
    "bin/photobear"
  ],
  "LICENSE" => "mit",
  "MIN_PERL_VERSION" => "5.024",
  "NAME" => "App::Photobear",
  "PREREQ_PM" => {
    "Capture::Tiny" => "0.40",
    "Carp" => "1.2",
    "Data::Dumper" => "2.1",
    "FindBin" => "1.3",
    "HTTP::Tiny" => 0,
    "JSON::PP" => 0,
    "PerlIO::encoding" => 0
  },
  "VERSION" => "0.1.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Capture::Tiny" => "0.40",
  "Carp" => "1.2",
  "Data::Dumper" => "2.1",
  "FindBin" => "1.3",
  "HTTP::Tiny" => 0,
  "JSON::PP" => 0,
  "PerlIO::encoding" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
