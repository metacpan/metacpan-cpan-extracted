# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.031.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Collection of CLI utilities for Dist::Zilla",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-DzilUtils",
  "EXE_FILES" => [
    "script/list-dist-deps",
    "script/list-dzil-bundle-contents",
    "script/list-dzil-bundles",
    "script/list-dzil-plugin-roles",
    "script/list-dzil-plugins",
    "script/list-dzil-roles"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "App::DzilUtils",
  "PREREQ_PM" => {
    "Complete::Dist::Zilla" => "0.02",
    "Config::IOD::Reader" => "0.344",
    "IPC::System::Options" => "0.339",
    "JSON::MaybeXS" => 0,
    "Module::List" => 0,
    "Module::Load" => 0,
    "Perinci::CmdLine::Any" => "0.09",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.120",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Complete::Dist::Zilla" => "0.02",
  "Config::IOD::Reader" => "0.344",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "IPC::System::Options" => "0.339",
  "JSON::MaybeXS" => 0,
  "Module::List" => 0,
  "Module::Load" => 0,
  "Perinci::CmdLine::Any" => "0.09",
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
