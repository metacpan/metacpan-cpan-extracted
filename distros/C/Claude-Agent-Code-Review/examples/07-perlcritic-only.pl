#!/usr/bin/env perl

=head1 NAME

07-perlcritic-only.pl - Deterministic Perl::Critic analysis (no AI)

=head1 SYNOPSIS

    # Run with default severity (4=stern)
    perl examples/07-perlcritic-only.pl lib/

    # Set severity via environment
    PERLCRITIC_SEVERITY=3 perl examples/07-perlcritic-only.pl lib/

    # Use custom profile
    PERLCRITIC_PROFILE=.perlcriticrc perl examples/07-perlcritic-only.pl lib/

=head1 DESCRIPTION

This example runs B<only> Perl::Critic static analysis without any AI.
This is ideal for CI/CD pipelines where you need:

=over 4

=item * B<100% deterministic results> - same output every run

=item * B<No API costs> - runs entirely locally

=item * B<Fast execution> - no network calls

=item * B<Reproducible builds> - results don't vary

=back

Unlike the combined AI+Perl::Critic examples, this script does not require
an API key and produces identical results on every run.

=head1 ENVIRONMENT VARIABLES

=over 4

=item * C<PERLCRITIC_SEVERITY> - Severity level 1-5 (default: 4)

=item * C<PERLCRITIC_PROFILE> - Path to custom .perlcriticrc file

=back

=head1 PERLCRITIC SEVERITY LEVELS

=over 4

=item * 1 = brutal (strictest)

=item * 2 = cruel

=item * 3 = harsh

=item * 4 = stern (default)

=item * 5 = gentle (most permissive)

=back

=head1 REQUIREMENTS

Requires Perl::Critic to be installed:

    cpanm Perl::Critic

=head1 EXIT CODES

=over 4

=item * 0 - No issues found (perlcritic check passed)

=item * 1 - High severity issues

=item * 2 - Critical issues

=back

=head1 CI/CD INTEGRATION

Example GitHub Actions step:

    - name: Perl::Critic Check
      run: |
        cpanm -n Perl::Critic
        PERLCRITIC_SEVERITY=4 perl examples/07-perlcritic-only.pl lib/

=cut

use strict;
use warnings;
use lib 'lib', '../lib';

use Claude::Agent::Code::Review::Perlcritic;
use Claude::Agent::Code::Review::Options;
use Claude::Agent::Code::Review::Report;

# Perlcritic-only review - no AI, fully deterministic
# Perfect for CI/CD pipelines where consistent results are required

# Check if perlcritic is available
unless (Claude::Agent::Code::Review::Perlcritic->is_available) {
    die "Perl::Critic is not installed. Install with: cpanm Perl::Critic\n";
}

my $options = Claude::Agent::Code::Review::Options->new(
    perlcritic          => 1,
    perlcritic_severity => $ENV{PERLCRITIC_SEVERITY} // 4,  # Default: stern
    perlcritic_profile  => $ENV{PERLCRITIC_PROFILE},        # Optional
);

my $target = $ARGV[0] // 'lib/';

print "=" x 60, "\n";
print "PERL::CRITIC STATIC ANALYSIS\n";
print "=" x 60, "\n";
print "Target: $target\n";
print "Severity: ", $options->perlcritic_severity, " (1=brutal, 5=gentle)\n";
if ($options->perlcritic_profile) {
    print "Profile: ", $options->perlcritic_profile, "\n";
}
print "=" x 60, "\n\n";

# Run perlcritic directly (no AI involved)
my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
    paths   => [$target],
    options => $options,
);

# Create report for consistent output
my $report = Claude::Agent::Code::Review::Report->new(
    summary => sprintf("Perl::Critic found %d issues", scalar(@issues)),
    issues  => \@issues,
);

print $report->as_text;

# Exit codes for CI
if ($report->has_critical_issues) {
    print STDERR "\nFATAL: Critical issues found!\n";
    exit(2);
}
if ($report->has_high_issues) {
    print STDERR "\nWARNING: High severity issues found!\n";
    exit(1);
}

print "\nPerlcritic check passed.\n" if !$report->has_issues;
exit(0);
