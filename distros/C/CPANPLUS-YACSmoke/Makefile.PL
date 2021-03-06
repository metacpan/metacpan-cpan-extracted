# This Makefile.PL for CPANPLUS-YACSmoke was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.48.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Yet Another CPANPLUS Smoke Tester",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "CONFIGURE_REQUIRES" => {
    "CPANPLUS" => "0.88",
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "CPANPLUS-YACSmoke",
  "EXE_FILES" => [
    "bin/yactool"
  ],
  "LICENSE" => "perl",
  "NAME" => "CPANPLUS::YACSmoke",
  "PREREQ_PM" => {
    "CPANPLUS" => "0.9123",
    "CPANPLUS::Dist::Build" => "0.62",
    "ExtUtils::CBuilder" => 0,
    "ExtUtils::ParseXS" => 0,
    "File::Spec" => 0,
    "IPC::Cmd" => "0.72",
    "Module::Build" => "0.33",
    "Module::Load::Conditional" => 0,
    "Params::Check" => 0,
    "Parse::CPAN::Meta" => "1.4200",
    "SDBM_File" => 0,
    "Test::Reporter" => "1.34",
    "version" => "0.73"
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.47"
  },
  "VERSION" => "1.08",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

%WriteMakefileArgs = (
    %WriteMakefileArgs,
    clean => {FILES => 't/dummy-cpanplus'},
);

my %FallbackPrereqs = (
  "CPANPLUS" => "0.9123",
  "CPANPLUS::Dist::Build" => "0.62",
  "ExtUtils::CBuilder" => 0,
  "ExtUtils::ParseXS" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Cmd" => "0.72",
  "IPC::Open3" => 0,
  "Module::Build" => "0.33",
  "Module::Load::Conditional" => 0,
  "Params::Check" => 0,
  "Parse::CPAN::Meta" => "1.4200",
  "SDBM_File" => 0,
  "Test::More" => "0.47",
  "Test::Reporter" => "1.34",
  "version" => "0.73"
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.035
{
  require CPANPLUS::Backend;
  require CPANPLUS::Selfupdate;
  my $href = CPANPLUS::Selfupdate->new(CPANPLUS::Backend->new())->modules_for_feature('cpantest',1);
  requires( $_ => $href->{$_} ) for keys %$href;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.035
sub _add_prereq {
  my ($mm_key, $module, $version_or_range) = @_;
  $version_or_range ||= 0;
  warn "$module already exists in $mm_key (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $WriteMakefileArgs{$mm_key}{$module}
      and $WriteMakefileArgs{$mm_key}{$module} ne '0'
      and $WriteMakefileArgs{$mm_key}{$module} ne $version_or_range;
  warn "$module already exists in FallbackPrereqs (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $FallbackPrereqs{$module} and $FallbackPrereqs{$module} ne '0'
        and $FallbackPrereqs{$module} ne $version_or_range;
  $WriteMakefileArgs{$mm_key}{$module} = $FallbackPrereqs{$module} = $version_or_range;
  return;
}

sub requires { goto &runtime_requires }

sub runtime_requires {
  my ($module, $version_or_range) = @_;
  _add_prereq(PREREQ_PM => $module, $version_or_range);
}
