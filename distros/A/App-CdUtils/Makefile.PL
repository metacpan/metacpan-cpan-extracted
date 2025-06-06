# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "CLI utilities related to changing directories",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-CdUtils",
  "EXE_FILES" => [
    "script/cdpart-backend",
    "script/cdsibling-backend",
    "script/cdtarget-backend",
    "script/cdtree-backend"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "App::CdUtils",
  "PREREQ_PM" => {
    "Complete::Util" => "0.620",
    "Cwd" => 0,
    "File::Util::Test" => "0.631",
    "File::chdir" => 0,
    "Getopt::Long::Complete" => 0,
    "Path::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.009",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Complete::Util" => "0.620",
  "Cwd" => 0,
  "File::Spec" => 0,
  "File::Util::Test" => "0.631",
  "File::chdir" => 0,
  "Getopt::Long::Complete" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Path::Tiny" => 0,
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

WriteMakefile(%WriteMakefileArgs);
