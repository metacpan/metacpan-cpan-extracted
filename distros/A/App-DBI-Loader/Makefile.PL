
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A tiny script to load CSV/TSV contents into a database table via DBI",
  "AUTHOR" => "Yasutaka ATARASHI <yakex\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-DBI-Loader",
  "EXE_FILES" => [
    "bin/dbiloader"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::DBI::Loader",
  "PREREQ_PM" => {
    "DBI" => 0,
    "Getopt::Config::FromPod" => 0,
    "String::Unescape" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "VERSION" => "v0.0.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DBI" => 0,
  "File::Spec" => 0,
  "Getopt::Config::FromPod" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "String::Unescape" => 0,
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



