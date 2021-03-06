# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.007.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A fast and small hybrid crypto system",
  "AUTHOR" => "Leon Timmermans <leont\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Crypt-ECDH_ES",
  "EXE_FILES" => [
    "script/ecdhes-keygen"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Crypt::ECDH_ES",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Crypt::Curve25519" => 0,
    "Crypt::Rijndael" => 0,
    "Digest::SHA" => 0,
    "Exporter" => "5.57",
    "Getopt::Long" => 0,
    "MIME::Base64" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Crypt::Curve25519" => 0,
  "Crypt::Rijndael" => 0,
  "Digest::SHA" => 0,
  "Exporter" => "5.57",
  "Getopt::Long" => 0,
  "MIME::Base64" => 0,
  "Test::More" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

if ( $^O eq 'MSWin32' ) {
	$WriteMakefileArgs{PREREQ_PM}{'Win32::API'} = '0';
}

WriteMakefile(%WriteMakefileArgs);
