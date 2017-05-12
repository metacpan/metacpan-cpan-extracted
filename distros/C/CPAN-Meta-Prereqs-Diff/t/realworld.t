
use strict;
use warnings;

use Test::More tests => 2;

use CPAN::Meta::Prereqs::Diff;
my $new_prereqs = {
  "configure" => { "requires" => { "ExtUtils::MakeMaker" => "6.17" } },
  "develop"   => {
    "requires" => {
      "Dist::Zilla"                             => "5.006",
      "Dist::Zilla::Plugin::OnlyCorePrereqs"    => "0.003",
      "Dist::Zilla::Plugin::PerlVersionPrereqs" => "0",
      "Dist::Zilla::Plugin::Prereqs"            => "0",
      "Dist::Zilla::Plugin::RemovePrereqs"      => "0",
      "Dist::Zilla::PluginBundle::DAGOLDEN"     => "0.052",
      "File::Spec"                              => "0",
      "File::Temp"                              => "0",
      "IO::Handle"                              => "0",
      "IPC::Open3"                              => "0",
      "Pod::Coverage::TrustPod"                 => "0",
      "Test::CPAN::Meta"                        => "0",
      "Test::More"                              => "0",
      "Test::Pod"                               => "1.41",
      "Test::Pod::Coverage"                     => "1.08"
    }
  },
  "runtime" => {
    "requires" => {
      "Carp"     => "0",
      "perl"     => "5.008001",
      "strict"   => "0",
      "warnings" => "0"
    }
  },
  "test" => {
    "recommends" => {
      "CPAN::Meta"               => "0",
      "CPAN::Meta::Requirements" => "0",
      "Test::FailWarnings"       => "0"
    },
    "requires" => {
      "Exporter"              => "0",
      "ExtUtils::MakeMaker"   => "0",
      "File::Spec::Functions" => "0",
      "List::Util"            => "0",
      "Test::More"            => "0.96",
      "base"                  => "0",
      "lib"                   => "0",
      "subs"                  => "0"
    },
  }
};

my $old_prereqs = {
  "configure" => {
    "requires" => {
      "ExtUtils::MakeMaker" => "6.30"
    }
  },
  "develop" => {
    "requires" => {
      "Pod::Coverage::TrustPod" => "0",
      "Test::CPAN::Meta"        => "0",
      "Test::Pod"               => "1.41",
      "Test::Pod::Coverage"     => "1.08"
    }
  },
  "runtime" => {
    "requires" => {
      "Carp"     => "0",
      "perl"     => "5.008001",
      "strict"   => "0",
      "warnings" => "0"
    }
  },
  "test" => {
    "recommends" => {
      "Test::FailWarnings" => "0"
    },
    "requires" => {
      "Exporter"              => "0",
      "ExtUtils::MakeMaker"   => "0",
      "File::Find"            => "0",
      "File::Spec::Functions" => "0",
      "File::Temp"            => "0",
      "List::Util"            => "0",
      "Test::More"            => "0.96",
      "base"                  => "0",
      "lib"                   => "0",
      "subs"                  => "0"
    }
  }
};

my $diff = CPAN::Meta::Prereqs::Diff->new(
  new_prereqs => $new_prereqs,
  old_prereqs => $old_prereqs,
);
our $context = "";

sub my_subtest ($$) {

  #note "Beginning: $_[0] ]---";
  local $context = " ($_[0])";
  $_[1]->();

  #note "Ending: $_[0] ]---";
}

my_subtest "Basic" => sub {
  my $i = 0;
  for my $diff_entry ( $diff->diff ) {
    note $diff_entry->describe;
    $i++;
  }
  is( $i, 5, "5 differences with basic settings$context" );
};

my_subtest "Develop" => sub {
  my $i = 0;
  for my $diff_entry ( $diff->diff( phases => [qw( configure build runtime test develop )] ) ) {
    note $diff_entry->describe;
    $i++;
  }
  is( $i, 16, "5 differences with develop deps$context" );
};
