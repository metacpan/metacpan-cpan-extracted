#!/usr/bin/env perl
#
# Perl Hooks Example
#
# This example demonstrates how to use Perl hook callbacks
# to intercept and control tool execution.
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;
use Claude::Agent::Hook::Matcher;
use Claude::Agent::Hook::Result;

# Define PreToolUse hooks that run BEFORE a tool executes
my $pre_tool_hooks = [
    # Hook for all tools - log every tool call
    Claude::Agent::Hook::Matcher->new(
        hooks => [sub {
            my ($input, $tool_use_id, $context) = @_;
            my $tool_name = $input->{tool_name};
            say "[LOG] Tool called: $tool_name";
            return Claude::Agent::Hook::Result->proceed();
        }],
    ),

    # Hook for Glob tool - modify the pattern
    Claude::Agent::Hook::Matcher->new(
        matcher => 'Glob',
        hooks   => [sub {
            my ($input, $tool_use_id, $context) = @_;
            my $pattern = $input->{tool_input}{pattern} // '';
            say "[HOOK] Glob pattern requested: $pattern";

            # Example: could modify the pattern here
            # return Claude::Agent::Hook::Result->allow(
            #     updated_input => { pattern => '*.pm' },
            #     reason => 'Modified pattern',
            # );

            return Claude::Agent::Hook::Result->proceed();
        }],
    ),

    # Hook for Read tool - block reading certain files
    Claude::Agent::Hook::Matcher->new(
        matcher => 'Read',
        hooks   => [sub {
            my ($input, $tool_use_id, $context) = @_;
            my $file_path = $input->{tool_input}{file_path} // '';

            # Block reading .env files (security example)
            if ($file_path =~ /\.env$/i) {
                say "[HOOK] BLOCKED: Cannot read .env files!";
                return Claude::Agent::Hook::Result->deny(
                    reason => 'Reading .env files is not allowed',
                );
            }

            say "[HOOK] Allowing read: $file_path";
            return Claude::Agent::Hook::Result->proceed();
        }],
    ),
];

# Define PostToolUse hooks that run AFTER a tool completes
my $post_tool_hooks = [
    Claude::Agent::Hook::Matcher->new(
        hooks => [sub {
            my ($input, $tool_use_id, $context) = @_;
            my $tool_name = $input->{tool_name};
            say "[LOG] Tool completed: $tool_name";
            return Claude::Agent::Hook::Result->proceed();
        }],
    ),
];

# Configure options with hooks
my $options = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob', 'Grep'],  # Only read-only tools
    permission_mode => 'bypassPermissions',
    max_turns       => 5,
    hooks           => {
        PreToolUse  => $pre_tool_hooks,
        PostToolUse => $post_tool_hooks,
    },
);

# Send a query that will trigger our hooks
my $iter = query(
    prompt  => 'Use the Glob tool to list all .pm files in the lib directory.',
    options => $options,
);

say "Sending query with Perl hooks...";
say "-" x 50;

while (my $msg = $iter->next) {
    if ($msg->isa('Claude::Agent::Message::Assistant')) {
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
