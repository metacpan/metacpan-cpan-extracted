
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Document Availability Information API",
  "AUTHOR" => "Jakob Vo\x{df}",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DAIA",
  "EXE_FILES" => [
    "bin/daia"
  ],
  "LICENSE" => "perl",
  "NAME" => "DAIA",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Carp::Clan" => 0,
    "Data::Validate::URI" => 0,
    "DateTime" => 0,
    "DateTime::Duration" => 0,
    "DateTime::Format::Duration" => 0,
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "IO::Scalar" => 0,
    "JSON" => 0,
    "LWP::Simple" => 0,
    "POSIX" => 0,
    "Pod::Usage" => 0,
    "Scalar::Util" => 0,
    "XML::LibXML::Simple" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.43",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Carp::Clan" => 0,
  "Data::Validate::URI" => 0,
  "DateTime" => 0,
  "DateTime::Duration" => 0,
  "DateTime::Format::Duration" => 0,
  "Getopt::Long" => 0,
  "IO::File" => 0,
  "IO::Scalar" => 0,
  "JSON" => 0,
  "LWP::Simple" => 0,
  "POSIX" => 0,
  "Pod::Usage" => 0,
  "Scalar::Util" => 0,
  "XML::LibXML::Simple" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



