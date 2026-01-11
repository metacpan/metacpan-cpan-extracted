#!/usr/bin/env perl

=head1 NAME

04-json-output.pl - Output review results as JSON

=head1 SYNOPSIS

    # Review and output JSON
    perl examples/04-json-output.pl lib/

    # Pipe to jq for pretty printing
    perl examples/04-json-output.pl lib/ | jq .

    # Save to file
    perl examples/04-json-output.pl lib/ > review-results.json

    # Enable debug mode (JSON still goes to stdout)
    CLAUDE_AGENT_DEBUG=1 perl examples/04-json-output.pl lib/ 2>/dev/null

=head1 DESCRIPTION

This example demonstrates JSON output for integration with other tools,
CI/CD pipelines, or custom reporting systems.

The JSON output includes:

=over 4

=item * summary - Brief overview of findings

=item * issues - Array of issue objects with severity, category, file, line, description

=item * metrics - Optional metrics about the review (files reviewed, etc.)

=back

=head1 DEBUG MODE

Set C<CLAUDE_AGENT_DEBUG=1> to see API interactions on stderr.
The JSON output remains clean on stdout for piping.

=head1 EXAMPLE OUTPUT

    {
      "summary": "Found 3 issues",
      "issues": [
        {
          "severity": "high",
          "category": "security",
          "file": "lib/App.pm",
          "line": 42,
          "description": "SQL injection vulnerability"
        }
      ]
    }

=cut

use strict;
use warnings;
use lib 'lib', '../lib';

use Claude::Agent::Code::Review qw(review_files);
use Claude::Agent::Code::Review::Options;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $options = Claude::Agent::Code::Review::Options->new(
    categories      => ['bugs', 'security', 'style', 'performance'],
    severity        => 'low',
    permission_mode => 'bypassPermissions',  # For automated/CI usage
);

my $target = $ARGV[0] // 'lib/';

my $report = review_files(
    paths   => [$target],
    options => $options,
    loop    => $loop,
)->get;

# Output as JSON for integration with other tools
print $report->as_json, "\n";
