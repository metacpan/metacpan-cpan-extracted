# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Encrypts/decrypts text and verifies decrypted text with a checksum and a random initialization vector.",
  "AUTHOR" => "Adam Hopkins <srchulo\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Crypt-Mode-CBC-Easy",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "Crypt::Mode::CBC::Easy",
  "PREREQ_PM" => {
    "Bytes::Random::Secure" => 0,
    "Carp" => 0,
    "Crypt::CBC" => 0,
    "Crypt::Mode::CBC" => 0,
    "Digest::SHA" => 0,
    "MIME::Base64" => 0,
    "Mouse" => 0,
    "strict" => 0
  },
  "VERSION" => "0.006",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "Bytes::Random::Secure" => 0,
  "Carp" => 0,
  "Crypt::CBC" => 0,
  "Crypt::Mode::CBC" => 0,
  "Digest::SHA" => 0,
  "MIME::Base64" => 0,
  "Mouse" => 0,
  "strict" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
