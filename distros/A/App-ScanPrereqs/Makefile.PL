# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Scan files/directories for prerequisites",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-ScanPrereqs",
  "EXE_FILES" => [
    "script/scan-prereqs"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "App::ScanPrereqs",
  "PREREQ_PM" => {
    "Data::Sah::Compiler::perl::TH::array" => "0.914",
    "Data::Sah::Compiler::perl::TH::bool" => "0.914",
    "Data::Sah::Compiler::perl::TH::str" => "0.914",
    "Data::Sah::Filter::perl::Path::expand_tilde_when_on_unix" => 0,
    "Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix" => 0,
    "File::Find" => 0,
    "Filename::Type::Backup" => 0,
    "Log::ger" => "0.038",
    "Module::CoreList" => 0,
    "Perinci::CmdLine::Any" => "0.154",
    "Perinci::CmdLine::Lite" => "1.924",
    "Perl::PrereqScanner" => 0,
    "Sah::Schema::pathname" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.006",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Sah::Compiler::perl::TH::array" => "0.914",
  "Data::Sah::Compiler::perl::TH::bool" => "0.914",
  "Data::Sah::Compiler::perl::TH::str" => "0.914",
  "Data::Sah::Filter::perl::Path::expand_tilde_when_on_unix" => 0,
  "Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix" => 0,
  "File::Find" => 0,
  "File::Spec" => 0,
  "Filename::Type::Backup" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Log::ger" => "0.038",
  "Module::CoreList" => 0,
  "Perinci::CmdLine::Any" => "0.154",
  "Perinci::CmdLine::Lite" => "1.924",
  "Perl::PrereqScanner" => 0,
  "Sah::Schema::pathname" => 0,
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
