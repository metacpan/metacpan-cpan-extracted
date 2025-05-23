# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.008.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Create a Dependencies::Stats section detailing summarized differences",
  "AUTHOR" => "Kent Fredric <kentnl\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "CPAN-Changes-Group-Dependencies-Stats",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "CPAN::Changes::Group::Dependencies::Stats",
  "PREREQ_PM" => {
    "CPAN::Changes" => "0.30",
    "CPAN::Changes::Group" => 0,
    "CPAN::Meta::Prereqs::Diff" => 0,
    "Carp" => 0,
    "Moo" => 0,
    "MooX::Lsub" => 0,
    "charnames" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "CPAN::Changes::Release" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::Differences" => 0,
    "Test::More" => 0,
    "utf8" => 0
  },
  "VERSION" => "0.002008",
  "test" => {
    "TESTS" => "t/*.t t/00-compile/*.t"
  }
);


my %FallbackPrereqs = (
  "CPAN::Changes" => "0.30",
  "CPAN::Changes::Group" => 0,
  "CPAN::Changes::Release" => 0,
  "CPAN::Meta::Prereqs::Diff" => 0,
  "Carp" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Moo" => 0,
  "MooX::Lsub" => 0,
  "Test::Differences" => 0,
  "Test::More" => 0,
  "charnames" => 0,
  "strict" => 0,
  "utf8" => 0,
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
