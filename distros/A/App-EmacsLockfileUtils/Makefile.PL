# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Utilities related to Emacs-style lock files",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-EmacsLockfileUtils",
  "EXE_FILES" => [
    "script/emacs-lockfile-get",
    "script/emacs-lockfile-lock",
    "script/emacs-lockfile-locked",
    "script/emacs-lockfile-unlock"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::EmacsLockfileUtils",
  "PREREQ_PM" => {
    "Data::Sah::Compiler::perl::TH::bool" => "0.914",
    "Data::Sah::Compiler::perl::TH::str" => "0.914",
    "Data::Sah::Filter::perl::Path::expand_tilde_when_on_unix" => 0,
    "Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix" => 0,
    "File::Lockfile::Emacs" => 0,
    "Perinci::CmdLine::Any" => "0.154",
    "Perinci::CmdLine::Lite" => "1.924",
    "Sah::Schema::filename" => 0,
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Sah::Compiler::perl::TH::bool" => "0.914",
  "Data::Sah::Compiler::perl::TH::str" => "0.914",
  "Data::Sah::Filter::perl::Path::expand_tilde_when_on_unix" => 0,
  "Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix" => 0,
  "File::Lockfile::Emacs" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Perinci::CmdLine::Any" => "0.154",
  "Perinci::CmdLine::Lite" => "1.924",
  "Sah::Schema::filename" => 0,
  "Test::More" => 0,
  "strict" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
