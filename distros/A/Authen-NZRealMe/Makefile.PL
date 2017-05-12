
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Integrate with RealMe login and identity services (formerly \"igovt logon\")",
  "AUTHOR" => "Grant McLean <grant\@catalyst.net.nz>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Authen-NZRealMe",
  "EXE_FILES" => [
    "bin/nzrealme"
  ],
  "LICENSE" => "perl",
  "NAME" => "Authen::NZRealMe",
  "PREREQ_PM" => {
    "Crypt::OpenSSL::RSA" => 0,
    "Crypt::OpenSSL::X509" => 0,
    "Data::UUID" => 0,
    "Date::Parse" => 0,
    "Digest::SHA" => 0,
    "IO::Compress::RawDeflate" => 0,
    "LWP" => 0,
    "MIME::Base64" => "3.11",
    "URI" => 0,
    "WWW::Curl" => 0,
    "XML::Generator" => 0,
    "XML::LibXML" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88"
  },
  "VERSION" => "1.16",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Crypt::OpenSSL::RSA" => 0,
  "Crypt::OpenSSL::X509" => 0,
  "Data::UUID" => 0,
  "Date::Parse" => 0,
  "Digest::SHA" => 0,
  "IO::Compress::RawDeflate" => 0,
  "LWP" => 0,
  "MIME::Base64" => "3.11",
  "Test::More" => "0.88",
  "URI" => 0,
  "WWW::Curl" => 0,
  "XML::Generator" => 0,
  "XML::LibXML" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



