#!/usr/bin/env perl

=head1 NAME

02-review-directory.pl - Review multiple directories with custom options

=head1 SYNOPSIS

    # Review default paths (lib/ and bin/)
    perl examples/02-review-directory.pl

    # Review specific paths
    perl examples/02-review-directory.pl lib/ t/

    # Enable debug mode
    CLAUDE_AGENT_DEBUG=1 perl examples/02-review-directory.pl lib/

=head1 DESCRIPTION

This example shows how to review multiple directories at once using
C<review_files()>. It demonstrates:

=over 4

=item * Reviewing multiple paths in a single call

=item * Setting custom focus areas for the review

=item * Limiting the maximum number of issues returned

=item * Grouping results by category

=back

The review focuses on error handling and input validation, checking for
bugs, security issues, and performance problems.

=head1 DEBUG MODE

Set C<CLAUDE_AGENT_DEBUG=1> to see detailed output including:

=over 4

=item * API requests and responses

=item * Tool calls made by Claude (Read, Glob, Grep)

=item * File access patterns

=back

=cut

use strict;
use warnings;
use lib 'lib';

use Claude::Agent::Code::Review qw(review_files);
use Claude::Agent::Code::Review::Options;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# Review multiple paths with custom options
my $options = Claude::Agent::Code::Review::Options->new(
    categories      => ['bugs', 'security', 'performance'],
    severity        => 'low',
    max_issues      => 20,
    focus_areas     => ['error handling', 'input validation'],
    permission_mode => 'bypassPermissions',  # For automated/CI usage
);

my @paths = @ARGV ? @ARGV : ('lib/', 'bin/');

print "Reviewing paths: ", join(', ', @paths), "\n";
print "Focus areas: ", join(', ', @{$options->focus_areas}), "\n";
print "-" x 60, "\n\n";

my $report = review_files(
    paths   => \@paths,
    options => $options,
    loop    => $loop,
)->get;

# Group issues by category
my $by_cat = $report->issues_by_category;

for my $category (sort keys %$by_cat) {
    my $issues = $by_cat->{$category};
    print "\n", uc($category), " (", scalar(@$issues), " issues):\n";

    for my $issue (@$issues) {
        printf "  [%s] %s - %s\n",
            $issue->severity,
            $issue->location,
            $issue->description;
    }
}

print "\n", "=" x 40, "\n";
print "Total: ", $report->issue_count, " issues\n";
