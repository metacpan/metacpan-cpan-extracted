
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "like mv, but clever",
  "AUTHOR" => "Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "App-mvr",
  "EXE_FILES" => [
    "bin/mvr"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::mvr",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "POSIX" => 0,
    "Path::Tiny" => "0.034",
    "Pod::Usage" => 0,
    "Try::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "IPC::Run3" => 0,
    "Test::Fatal" => 0,
    "Test::Is" => 0,
    "Test::More" => 0,
    "Test::Script::Run" => 0
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Capture::Tiny" => 0,
  "Carp" => 0,
  "Exporter" => 0,
  "File::Spec" => 0,
  "Getopt::Long" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "IPC::Run3" => 0,
  "Module::Build" => "0.3601",
  "POSIX" => 0,
  "Path::Tiny" => "0.034",
  "Pod::Usage" => 0,
  "Test::Fatal" => 0,
  "Test::Is" => 0,
  "Test::More" => 0,
  "Test::Script::Run" => 0,
  "Try::Tiny" => 0,
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

WriteMakefile(%WriteMakefileArgs);



