#!/usr/bin/env perl

=head1 NAME

05-security-focus.pl - Security-focused code audit

=head1 SYNOPSIS

    # Security audit of lib/
    perl examples/05-security-focus.pl lib/

    # Audit specific file
    perl examples/05-security-focus.pl lib/MyApp/Auth.pm

    # Enable debug mode
    CLAUDE_AGENT_DEBUG=1 perl examples/05-security-focus.pl lib/

=head1 DESCRIPTION

This example performs a security-focused code audit, checking for common
vulnerabilities from the OWASP Top 10 and other security issues.

Focus areas include:

=over 4

=item * SQL injection

=item * XSS (Cross-Site Scripting)

=item * Command injection

=item * Path traversal

=item * Authentication bypass

=item * Sensitive data exposure

=item * Insecure deserialization

=back

=head1 DEBUG MODE

Set C<CLAUDE_AGENT_DEBUG=1> to see detailed output including:

=over 4

=item * How Claude analyzes potential vulnerabilities

=item * Tool calls for reading and searching code

=item * The reasoning behind security findings

=back

=head1 EXIT CODES

=over 4

=item * 0 - No security issues found

=item * 1 - Low/medium severity issues

=item * 2 - High severity issues

=item * 3 - Critical security issues (immediate attention required!)

=back

=cut

use strict;
use warnings;
use lib 'lib', '../lib';

use Claude::Agent::Code::Review qw(review_files);
use Claude::Agent::Code::Review::Options;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# Security-focused review
my $options = Claude::Agent::Code::Review::Options->new(
    categories      => ['security'],
    severity        => 'low',
    permission_mode => 'bypassPermissions',  # For automated/CI usage
    focus_areas     => [
        'SQL injection',
        'XSS vulnerabilities',
        'command injection',
        'path traversal',
        'authentication bypass',
        'sensitive data exposure',
        'insecure deserialization',
    ],
);

my $target = $ARGV[0] // 'lib/';

print "=" x 60, "\n";
print "SECURITY AUDIT\n";
print "=" x 60, "\n";
print "Target: $target\n";
print "Focus: ", join(', ', @{$options->focus_areas}), "\n";
print "=" x 60, "\n\n";

my $report = review_files(
    paths   => [$target],
    options => $options,
    loop    => $loop,
)->get;

if (!$report->has_issues) {
    print "No security issues found.\n";
    exit(0);
}

# Display by severity
my $by_sev = $report->issues_by_severity;

for my $severity (qw(critical high medium low info)) {
    my $issues = $by_sev->{$severity} // [];
    next unless @$issues;

    print uc($severity), " SEVERITY (", scalar(@$issues), "):\n";
    print "-" x 40, "\n";

    for my $issue (@$issues) {
        print "\n";
        print "File: ", $issue->location, "\n";
        print "Issue: ", $issue->description, "\n";
        if ($issue->has_suggestion) {
            print "Fix: ", $issue->suggestion, "\n";
        }
    }
    print "\n";
}

print "=" x 60, "\n";
print "Total security issues: ", $report->issue_count, "\n";

# Exit codes for CI integration
exit(3) if $report->has_critical_issues;
exit(2) if $report->has_high_issues;
exit(1) if $report->has_issues;
exit(0);
