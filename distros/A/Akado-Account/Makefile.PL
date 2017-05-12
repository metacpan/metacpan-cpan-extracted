
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "get internet provider Akado account info",
  "AUTHOR" => "Ivan Bessarabov <ivan\@bessarabov.ru>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Akado-Account",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Akado::Account",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Digest::MD5" => 0,
    "HTTP::Request::Common" => 0,
    "LWP" => 0,
    "XML::XPath" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "1.2.0",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Digest::MD5" => 0,
  "HTTP::Request::Common" => 0,
  "LWP" => 0,
  "Test::More" => 0,
  "XML::XPath" => 0,
  "strict" => 0,
  "utf8" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



