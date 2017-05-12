
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Manipulate metadata in audio files",
  "AUTHOR" => "Egor Shipovalov <kogdaugodno\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Audio-Metadata",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Audio::Metadata",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "IO::File" => 0,
    "List::Util" => 0,
    "Module::Find" => 0,
    "Path::Class" => 0,
    "autodie" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Cwd" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Spec" => 0,
    "Test::Deep" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.16",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Any::Moose" => 0,
  "Cwd" => 0,
  "File::Basename" => 0,
  "File::Copy" => 0,
  "File::Spec" => 0,
  "IO::File" => 0,
  "List::Util" => 0,
  "Module::Find" => 0,
  "Path::Class" => 0,
  "Test::Deep" => 0,
  "Test::More" => 0,
  "autodie" => 0,
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



