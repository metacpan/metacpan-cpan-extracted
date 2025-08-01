# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Check extraneous/missing/incorrect prerequisites in dist.ini",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-LintPrereqs",
  "EXE_FILES" => [
    "script/lint-prereqs"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "App::LintPrereqs",
  "PREREQ_PM" => {
    "App::PDRUtils" => "0.06",
    "Config::IOD" => "0.353",
    "Data::Sah::Compiler::perl::TH::array" => "0.914",
    "Data::Sah::Compiler::perl::TH::bool" => "0.914",
    "Data::Sah::Compiler::perl::TH::str" => "0.914",
    "Exporter" => "5.57",
    "Fcntl" => 0,
    "File::Find" => 0,
    "File::Which" => 0,
    "Filename::Type::Backup" => 0,
    "IPC::System::Options" => "0.339",
    "Log::ger" => "0.038",
    "Module::CoreList::More" => 0,
    "Perinci::CmdLine::Any" => 0,
    "Perl::PrereqScanner" => 0,
    "Proc::ChildError" => 0,
    "Scalar::Util" => 0,
    "Sort::Sub" => "0.120",
    "Sort::Sub::prereq_ala_perlancar" => 0,
    "Version::Util" => "0.732",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.544",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::PDRUtils" => "0.06",
  "Config::IOD" => "0.353",
  "Data::Sah::Compiler::perl::TH::array" => "0.914",
  "Data::Sah::Compiler::perl::TH::bool" => "0.914",
  "Data::Sah::Compiler::perl::TH::str" => "0.914",
  "Exporter" => "5.57",
  "Fcntl" => 0,
  "File::Find" => 0,
  "File::Spec" => 0,
  "File::Which" => 0,
  "Filename::Type::Backup" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "IPC::System::Options" => "0.339",
  "Log::ger" => "0.038",
  "Module::CoreList::More" => 0,
  "Perinci::CmdLine::Any" => 0,
  "Perl::PrereqScanner" => 0,
  "Proc::ChildError" => 0,
  "Scalar::Util" => 0,
  "Sort::Sub" => "0.120",
  "Sort::Sub::prereq_ala_perlancar" => 0,
  "Test::More" => 0,
  "Version::Util" => "0.732",
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
