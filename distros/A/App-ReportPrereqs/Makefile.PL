use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "report prerequisite versions",
  "AUTHOR" => "Sven Kirmess <sven.kirmess\@kzone.ch>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-ReportPrereqs",
  "EXE_FILES" => [
    "bin/report-prereqs"
  ],
  "LICENSE" => "open_source",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "App::ReportPrereqs",
  "PREREQ_PM" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Basename" => 0,
    "Getopt::Long" => 0,
    "HTTP::Tiny" => "0.014",
    "List::Util" => 0,
    "Module::CPANfile" => 0,
    "Module::Path" => 0,
    "strict" => 0,
    "version" => "0.77",
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
    "lib" => 0
  },
  "VERSION" => "0.006",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::Basename" => 0,
  "Getopt::Long" => 0,
  "HTTP::Tiny" => "0.014",
  "List::Util" => 0,
  "Module::CPANfile" => 0,
  "Module::Path" => 0,
  "Test::More" => "0.88",
  "lib" => 0,
  "strict" => 0,
  "version" => "0.77",
  "warnings" => 0
);

if (is_smoker()) {
  $WriteMakefileArgs{test}{TESTS} .= " xt/smoke/*.t";
  _add_smoker_test_requirements();
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

sub _add_prereq {
  my ($mm_key, $module, $version_or_range) = @_;
  $version_or_range ||= 0;
  warn "$module already exists in $mm_key (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $WriteMakefileArgs{$mm_key}{$module}
      and $WriteMakefileArgs{$mm_key}{$module} ne '0'
      and $WriteMakefileArgs{$mm_key}{$module} ne $version_or_range;
  warn "$module already exists in FallbackPrereqs (at version $FallbackPrereqs{$module}) -- need to do a sane metamerge!"
    if exists $FallbackPrereqs{$module} and $FallbackPrereqs{$module} ne '0'
        and $FallbackPrereqs{$module} ne $version_or_range;
  $WriteMakefileArgs{$mm_key}{$module} = $FallbackPrereqs{$module} = $version_or_range;
  return;
}

sub is_smoker {
  return $ENV{AUTOMATED_TESTING} ? 1 : 0;
}

sub test_requires {
  my ($module, $version_or_range) = @_;
  _add_prereq(TEST_REQUIRES => $module, $version_or_range);
}

sub _add_smoker_test_requirements {
  test_requires('Capture::Tiny', 0);
  test_requires('Cwd', 0);
  test_requires('File::Spec', 0);
  test_requires('Test::MockModule', 0);
}
