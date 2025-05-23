# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "DSA Signatures and Key Generation",
  "AUTHOR" => "Benjamin Trott <ben\@sixapart.com>",
  "BUILD_REQUIRES" => {
    "Convert::PEM" => "0.13",
    "Data::Buffer" => "0.01",
    "ExtUtils::MakeMaker" => "6.42",
    "File::Which" => "0.05",
    "Math::BigInt" => "1.78"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.42"
  },
  "DISTNAME" => "Crypt-DSA",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Crypt::DSA",
  "PREREQ_PM" => {
    "Convert::ASN1" => 0,
    "Convert::PEM" => "0.13",
    "Crypt::URandom" => 0,
    "Data::Buffer" => "0.01",
    "Digest::SHA" => 0,
    "File::Spec" => 0,
    "File::Which" => "0.05",
    "IPC::Open3" => 0,
    "MIME::Base64" => 0,
    "Math::BigInt" => "1.78"
  },
  "TEST_REQUIRES" => {
    "Crypt::DES_EDE3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "1.19",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Convert::ASN1" => 0,
  "Convert::PEM" => "0.13",
  "Crypt::DES_EDE3" => 0,
  "Crypt::URandom" => 0,
  "Data::Buffer" => "0.01",
  "Digest::SHA" => 0,
  "ExtUtils::MakeMaker" => "6.42",
  "File::Spec" => 0,
  "File::Which" => "0.05",
  "IPC::Open3" => 0,
  "MIME::Base64" => 0,
  "Math::BigInt" => "1.78",
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
