
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Git Changesets, tools for managing your git changes",
  "AUTHOR" => "Grant Street Group <developers\@grantstreet.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Gitc",
  "EXE_FILES" => [
    "bin/git-merge-theirs",
    "bin/gitc",
    "bin/gitc-add-user",
    "bin/gitc-archive-tags",
    "bin/gitc-branch",
    "bin/gitc-branch-point",
    "bin/gitc-cancel",
    "bin/gitc-changesets-in",
    "bin/gitc-current-branch",
    "bin/gitc-diff",
    "bin/gitc-diff-versions",
    "bin/gitc-diffsites",
    "bin/gitc-edit",
    "bin/gitc-fail",
    "bin/gitc-group",
    "bin/gitc-history",
    "bin/gitc-import-tags",
    "bin/gitc-list",
    "bin/gitc-log",
    "bin/gitc-open",
    "bin/gitc-pass",
    "bin/gitc-project-name",
    "bin/gitc-promote",
    "bin/gitc-promoted",
    "bin/gitc-quickfix",
    "bin/gitc-rebase",
    "bin/gitc-review",
    "bin/gitc-setup",
    "bin/gitc-show",
    "bin/gitc-status",
    "bin/gitc-submit",
    "bin/gitc-sync",
    "bin/gitc-touch",
    "bin/gitc-unpromoted"
  ],
  "LICENSE" => "open_source",
  "NAME" => "App::Gitc",
  "PREREQ_PM" => {
    "Algorithm::Dependency::Ordered" => 0,
    "Algorithm::Dependency::Source::HoA" => 0,
    "Carp" => 0,
    "Class::MOP" => 0,
    "Cwd" => 0,
    "Date::Format" => 0,
    "Date::Parse" => 0,
    "Date::PeriodParser" => 0,
    "Email::Simple" => 0,
    "Exporter" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "Getopt::Long" => 0,
    "Hash::Merge::Simple" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "POSIX" => 0,
    "Term::ReadLine" => 0,
    "Test::More" => 0,
    "Text::Levenshtein" => 0,
    "Time::Local" => 0,
    "Try::Tiny" => 0,
    "YAML" => 0,
    "YAML::Syck" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "Test::CheckDeps" => "0.006",
    "Test::More" => "0.94"
  },
  "VERSION" => "0.60",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



