#!/usr/bin/env perl
#
# Subagents Example
#
# This example demonstrates how to define custom subagents
# that Claude can spawn for specialized tasks.
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;
use Claude::Agent::Subagent;

# Define a code reviewer subagent
my $code_reviewer = Claude::Agent::Subagent->new(
    description => 'Expert code reviewer that analyzes code quality',
    prompt      => 'You are an expert code reviewer. Analyze the provided code for:
- Code quality and readability
- Potential bugs or issues
- Best practices compliance
- Performance considerations
Provide constructive feedback.',
    tools       => ['Read', 'Glob', 'Grep'],
    model       => 'sonnet',
);

# Define a documentation writer subagent
my $doc_writer = Claude::Agent::Subagent->new(
    description => 'Technical writer that creates documentation',
    prompt      => 'You are a technical documentation writer. Create clear,
concise documentation for code and APIs. Include:
- Overview and purpose
- Usage examples
- Parameter descriptions
- Return value documentation',
    tools       => ['Read', 'Glob'],
    model       => 'haiku',
);

# Define a test writer subagent
my $test_writer = Claude::Agent::Subagent->new(
    description => 'Test engineer that writes comprehensive tests',
    prompt      => 'You are a test engineer. Write comprehensive tests that cover:
- Happy path scenarios
- Edge cases
- Error handling
- Integration points
Use appropriate testing frameworks for the language.',
    tools       => ['Read', 'Glob', 'Grep', 'Write'],
    model       => 'sonnet',
);

# Configure options with subagents
my $options = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob', 'Grep', 'Task'],
    permission_mode => 'bypassPermissions',
    max_turns       => 10,
    agents          => {
        'code-reviewer' => $code_reviewer,
        'doc-writer'    => $doc_writer,
        'test-writer'   => $test_writer,
    },
);

# Send a query that might use subagents
my $iter = query(
    prompt  => 'Review the lib/Claude/Agent.pm file for code quality.',
    options => $options,
);

say "Sending query with subagents available...";
say "-" x 50;

while (my $msg = $iter->next) {
    if ($msg->isa('Claude::Agent::Message::System')) {
        if ($msg->subtype eq 'subagent_start') {
            say "[Subagent started: " . ($msg->data->{agent_name} // 'unknown') . "]";
        }
        elsif ($msg->subtype eq 'subagent_stop') {
            say "[Subagent finished]";
        }
    }
    elsif ($msg->isa('Claude::Agent::Message::Assistant')) {
        for my $block (@{$msg->content_blocks}) {
            if ($block->isa('Claude::Agent::Content::Text')) {
                print $block->text;
            }
        }
    }
    elsif ($msg->isa('Claude::Agent::Message::Result')) {
        say "\n", "-" x 50;
        say "Completed!";
        last;
    }
}
