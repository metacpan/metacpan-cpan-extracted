#!/usr/bin/env perl

=head1 NAME

01-basic-review.pl - Basic AI-powered code review

=head1 SYNOPSIS

    # Standard usage
    perl examples/01-basic-review.pl lib/MyModule.pm

    # Review a directory
    perl examples/01-basic-review.pl lib/

    # Enable debug mode to see Claude API interactions
    CLAUDE_AGENT_DEBUG=1 perl examples/01-basic-review.pl lib/

=head1 DESCRIPTION

This example demonstrates the simplest way to use Claude::Agent::Code::Review.
It uses the C<review()> function which auto-detects the target type (file,
directory, or diff) and performs an AI-powered code review.

The review checks for bugs, security issues, and style problems at medium
severity or higher.

=head1 DEBUG MODE

Set C<CLAUDE_AGENT_DEBUG=1> to see detailed output including:

=over 4

=item * API requests and responses

=item * Tool calls made by Claude

=item * Token usage statistics

=back

=head1 EXIT CODES

=over 4

=item * 0 - No critical issues found

=item * 1 - Critical issues found

=back

=cut

use strict;
use warnings;
use lib 'lib';

use Claude::Agent::Code::Review qw(review);
use Claude::Agent::Code::Review::Options;
use IO::Async::Loop;

# Create event loop
my $loop = IO::Async::Loop->new;

# Configure review options
my $options = Claude::Agent::Code::Review::Options->new(
    categories      => ['bugs', 'security', 'style'],
    severity        => 'medium',
    permission_mode => 'bypassPermissions',  # For automated/CI usage
);

# Get target from command line or use default
my $target = $ARGV[0] // 'lib/';

print "Reviewing: $target\n";
print "Categories: ", join(', ', @{$options->categories}), "\n";
print "Minimum severity: ", $options->severity, "\n";
print "-" x 60, "\n\n";

my $report = review(
    target  => $target,
    options => $options,
    loop    => $loop,
)->get;

# Display results
print $report->as_text;

# Exit with error code if critical issues found
exit(1) if $report->has_critical_issues;
exit(0);
