
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Easy DBI access from CGI::Application",
  "AUTHOR" => "Mark Stosberg <mark\@stosberg.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CGI-Application-Plugin-DBH",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CGI::Application::Plugin::DBH",
  "PREREQ_PM" => {
    "CGI::Application" => 0,
    "DBI" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {
    "DBD::Mock" => "0.11",
    "Test::MockObject" => "1.20120301",
    "Test::More" => "1.001002"
  },
  "VERSION" => "4.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CGI::Application" => 0,
  "DBD::Mock" => "0.11",
  "DBI" => 0,
  "Test::MockObject" => "1.20120301",
  "Test::More" => "1.001002",
  "parent" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



