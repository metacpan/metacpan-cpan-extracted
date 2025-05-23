# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.009.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Format your Changes file ( or a section of it ) in Markdown",
  "AUTHOR" => "Kent Fredric <kentnl\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "CPAN-Changes-Markdown",
  "EXE_FILES" => [
    "bin/cpan-changes-markdown"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "CPAN::Changes::Markdown",
  "PREREQ_PM" => {
    "CPAN::Changes" => 0,
    "Carp" => 0,
    "Moo" => "1.000008",
    "Path::Tiny" => 0,
    "Role::Tiny" => 0,
    "Sub::Exporter::Progressive" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => 0,
    "charnames" => 0
  },
  "VERSION" => "1.000002",
  "test" => {
    "TESTS" => "t/*.t t/00-compile/*.t"
  }
);


my %FallbackPrereqs = (
  "CPAN::Changes" => 0,
  "Carp" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Moo" => "1.000008",
  "Path::Tiny" => 0,
  "Role::Tiny" => 0,
  "Sub::Exporter::Progressive" => 0,
  "Test::More" => 0,
  "charnames" => 0,
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
