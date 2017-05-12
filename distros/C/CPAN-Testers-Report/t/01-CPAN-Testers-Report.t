use strict;
use warnings;

use Test::More 0.88;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

my @classes = qw (
  CPAN::Testers::Report
  CPAN::Testers::Fact::TestSummary
  CPAN::Testers::Fact::TestOutput
  CPAN::Testers::Fact::LegacyReport
  CPAN::Testers::Fact::TesterComment
  CPAN::Testers::Fact::Prereqs
  CPAN::Testers::Fact::InstalledModules
  CPAN::Testers::Fact::TestEnvironment
  CPAN::Testers::Fact::PerlConfig
);

plan tests => scalar @classes;

require_ok($_) for @classes;

