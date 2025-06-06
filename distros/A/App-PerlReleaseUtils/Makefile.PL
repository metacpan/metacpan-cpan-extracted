# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Collection of utilities related to Perl distribution releases",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-PerlReleaseUtils",
  "EXE_FILES" => [
    "script/grep-perl-release"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "App::PerlReleaseUtils",
  "PREREQ_PM" => {
    "Data::Sah::Compiler::perl::TH::bool" => "0.911",
    "Data::Sah::Compiler::perl::TH::int" => "0.911",
    "Log::ger" => "0.038",
    "Perinci::CmdLine::Any" => "0.152",
    "Perinci::CmdLine::Lite" => "1.915",
    "Regexp::Pattern::Perl::Release" => 0,
    "Sah::Schema::posint" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Sah::Compiler::perl::TH::bool" => "0.911",
  "Data::Sah::Compiler::perl::TH::int" => "0.911",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Log::ger" => "0.038",
  "Perinci::CmdLine::Any" => "0.152",
  "Perinci::CmdLine::Lite" => "1.915",
  "Regexp::Pattern::Perl::Release" => 0,
  "Sah::Schema::posint" => 0,
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
