#!/usr/bin/env perl

=head1 NAME

03-review-staged.pl - Review staged git changes before committing

=head1 SYNOPSIS

    # Stage some changes first
    git add lib/MyModule.pm

    # Review staged changes
    perl examples/03-review-staged.pl

    # Enable debug mode
    CLAUDE_AGENT_DEBUG=1 perl examples/03-review-staged.pl

=head1 DESCRIPTION

This example shows how to use C<review_diff()> to review staged git changes
before committing. This is ideal for pre-commit hooks or manual review.

The script:

=over 4

=item * Runs C<git diff --cached> to get staged changes

=item * Performs AI review focusing on bugs and security

=item * Provides clear exit codes for CI integration

=back

=head1 DEBUG MODE

Set C<CLAUDE_AGENT_DEBUG=1> to see detailed output including:

=over 4

=item * The diff content being analyzed

=item * Claude's analysis process

=item * API token usage

=back

=head1 EXIT CODES

=over 4

=item * 0 - No issues or only low/medium severity issues

=item * 1 - High severity issues found

=item * 2 - Critical issues found (do not commit!)

=back

=head1 GIT HOOK USAGE

Add to C<.git/hooks/pre-commit>:

    #!/bin/sh
    perl examples/03-review-staged.pl
    exit $?

=cut

use strict;
use warnings;
use lib 'lib';

use Claude::Agent::Code::Review qw(review_diff);
use Claude::Agent::Code::Review::Options;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# Review staged changes before committing
my $options = Claude::Agent::Code::Review::Options->new(
    categories      => ['bugs', 'security'],
    severity        => 'medium',
    permission_mode => 'bypassPermissions',  # For automated/CI usage
);

print "Reviewing staged changes (git diff --cached)...\n";
print "-" x 60, "\n\n";

my $report = review_diff(
    staged  => 1,
    options => $options,
    loop    => $loop,
)->get;

if (!$report->has_issues) {
    print "No issues found in staged changes.\n";
    print "Safe to commit!\n";
    exit(0);
}

print $report->as_text;

if ($report->has_critical_issues) {
    print "\n*** CRITICAL ISSUES FOUND - DO NOT COMMIT ***\n";
    exit(2);
}

if ($report->has_high_issues) {
    print "\n*** HIGH SEVERITY ISSUES - Review before committing ***\n";
    exit(1);
}

print "\nConsider fixing the above issues before committing.\n";
exit(0);
