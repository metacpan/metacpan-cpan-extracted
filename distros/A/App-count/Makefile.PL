
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Counting utility for a file consisting of the fixed number of fields like CSV",
  "AUTHOR" => "Yasutaka ATARASHI <yakex\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-count",
  "EXE_FILES" => [
    "bin/count"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::count",
  "PREREQ_PM" => {
    "Encode" => 0,
    "Getopt::Config::FromPod" => 0,
    "Getopt::Long" => "2.36",
    "String::Unescape" => 0,
    "YAML::Any" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "VERSION" => "v0.1.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Encode" => 0,
  "File::Spec" => 0,
  "Getopt::Config::FromPod" => 0,
  "Getopt::Long" => "2.36",
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "String::Unescape" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "YAML::Any" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



