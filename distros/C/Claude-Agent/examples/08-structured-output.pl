#!/usr/bin/env perl
#
# Structured Output Example
#
# This example demonstrates how to request structured JSON output
# from Claude using a JSON schema.
#

use 5.020;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;
use Cpanel::JSON::XS;

# Define the output schema
my $output_schema = {
    type       => 'object',
    properties => {
        summary => {
            type        => 'string',
            description => 'A brief summary of the analysis',
        },
        files_found => {
            type  => 'integer',
            description => 'Number of files found',
        },
        file_types => {
            type  => 'array',
            items => {
                type       => 'object',
                properties => {
                    extension => { type => 'string' },
                    count     => { type => 'integer' },
                },
                required => ['extension', 'count'],
            },
            description => 'Breakdown by file type',
        },
        largest_files => {
            type  => 'array',
            items => {
                type       => 'object',
                properties => {
                    name => { type => 'string' },
                    path => { type => 'string' },
                },
                required => ['name', 'path'],
            },
            description => 'List of notable files',
        },
    },
    required => ['summary', 'files_found'],
};

# Configure options with structured output
my $options = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob', 'Grep', 'Bash'],
    permission_mode => 'bypassPermissions',
    max_turns       => 5,
    output_format   => {
        type   => 'json_schema',
        schema => $output_schema,
    },
);

# Send a query requesting structured output
my $iter = query(
    prompt  => 'Analyze the lib/ directory structure and provide a summary of the Perl modules.',
    options => $options,
);

say "Requesting structured output...";
say "-" x 50;

my $json_result;

while (my $msg = $iter->next) {
    if ($msg->isa('Claude::Agent::Message::Assistant')) {
        # Show progress
        for my $block (@{$msg->content_blocks}) {
            if ($block->isa('Claude::Agent::Content::Text')) {
                print $block->text;
            }
            elsif ($block->isa('Claude::Agent::Content::ToolUse')) {
                say "\n[Using tool: " . $block->name . "]";
            }
        }
    }
    elsif ($msg->isa('Claude::Agent::Message::Result')) {
        # Debug: show what fields are available
        if ($ENV{CLAUDE_AGENT_DEBUG}) {
            say "\nDEBUG Result message:";
            say "  subtype: " . ($msg->subtype // 'undef');
            my $has_so = $msg->can('has_structured_output') ? ($msg->has_structured_output ? 'yes' : 'no') : 'N/A';
            say "  has structured_output: $has_so";
            say "  structured_output: " . (defined $msg->structured_output ? ref($msg->structured_output) || $msg->structured_output : 'undef');
            say "  result length: " . (defined $msg->result ? length($msg->result) : 'undef');
        }
        # Check for structured_output first (preferred), then fall back to result
        $json_result = $msg->structured_output // $msg->result;
        last;
    }
}

# Parse and display the structured result
say "\n";
if ($json_result) {
    my $json = Cpanel::JSON::XS->new->utf8->pretty;

    # If it's already a hashref (structured_output), just encode it
    if (ref $json_result eq 'HASH' || ref $json_result eq 'ARRAY') {
        say "Structured Result:";
        say $json->encode($json_result);
    }
    else {
        # Try to parse as JSON string
        eval {
            my $data = $json->decode($json_result);
            say "Structured Result:";
            say $json->encode($data);
        };
        if ($@) {
            say "Raw result (not JSON): $json_result";
        }
    }
}
else {
    say "No result received.";
}

say "-" x 50;
say "Done!";
