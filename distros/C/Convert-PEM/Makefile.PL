# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Read/write encrypted ASN.1 PEM files",
  "AUTHOR" => "Benjamin Trott <cpan\@stupidfool.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Convert-PEM",
  "LICENSE" => "perl",
  "NAME" => "Convert::PEM",
  "PREREQ_PM" => {
    "Class::ErrorHandler" => 0,
    "Convert::ASN1" => "0.34",
    "Crypt::DES_EDE3" => 0,
    "Crypt::PRNG" => 0,
    "Digest::MD5" => 0,
    "MIME::Base64" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.13",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::ErrorHandler" => 0,
  "Convert::ASN1" => "0.34",
  "Crypt::DES_EDE3" => 0,
  "Crypt::PRNG" => 0,
  "Digest::MD5" => 0,
  "MIME::Base64" => 0,
  "Test::Exception" => 0,
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
