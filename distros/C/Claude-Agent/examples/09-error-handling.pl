#!/usr/bin/env perl
#
# Error Handling Example
#
# This example demonstrates proper error handling
# when using the Claude Agent SDK.
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;
use Claude::Agent::Error;
use Try::Tiny;

# Example 1: Handle CLI not found
say "Example 1: Handling CLI errors";
say "-" x 50;

try {
    my $options = Claude::Agent::Options->new(
        allowed_tools   => ['Read'],
        permission_mode => 'bypassPermissions',
    );

    my $iter = query(
        prompt  => 'Hello',
        options => $options,
    );

    while (my $msg = $iter->next) {
        if ($msg->isa('Claude::Agent::Message::Result')) {
            if ($msg->is_error) {
                say "Query failed: " . $msg->result;
            }
            else {
                say "Success: " . substr($msg->result // '', 0, 100) . "...";
            }
            last;
        }
    }
}
catch {
    if ($_->isa('Claude::Agent::Error::CLINotFound')) {
        say "ERROR: Claude CLI not found!";
        say "Please install it from: https://claude.ai/download";
    }
    elsif ($_->isa('Claude::Agent::Error::ProcessError')) {
        say "ERROR: Process failed!";
        say "Exit code: " . ($_->exit_code // 'unknown');
        say "Stderr: " . ($_->stderr // 'none');
    }
    elsif ($_->isa('Claude::Agent::Error::TimeoutError')) {
        say "ERROR: Operation timed out after " . $_->timeout_ms . "ms";
    }
    elsif ($_->isa('Claude::Agent::Error::JSONDecodeError')) {
        say "ERROR: Failed to parse response!";
        say "Line: " . ($_->line // 'unknown');
    }
    elsif ($_->isa('Claude::Agent::Error')) {
        say "ERROR: " . $_->message;
    }
    else {
        say "UNEXPECTED ERROR: $_";
    }
};

# Example 2: Validate options
say "\nExample 2: Option validation";
say "-" x 50;

try {
    # This should work fine
    my $valid_options = Claude::Agent::Options->new(
        permission_mode => 'bypassPermissions',
        max_turns       => 10,
    );
    say "Valid options created successfully";
}
catch {
    say "Failed to create options: $_";
};

# Example 3: Handle tool errors gracefully
say "\nExample 3: Tool error handling";
say "-" x 50;

try {
    my $options = Claude::Agent::Options->new(
        allowed_tools   => ['Bash'],
        permission_mode => 'bypassPermissions',
        max_turns       => 3,
    );

    my $iter = query(
        prompt  => 'Run the command: nonexistent_command_12345',
        options => $options,
    );

    while (my $msg = $iter->next) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            for my $block (@{$msg->content_blocks}) {
                if ($block->isa('Claude::Agent::Content::Text')) {
                    print $block->text;
                }
                elsif ($block->isa('Claude::Agent::Content::ToolResult')) {
                    if ($block->is_error) {
                        say "\n[Tool error: " . $block->text . "]";
                    }
                }
            }
        }
        elsif ($msg->isa('Claude::Agent::Message::Result')) {
            say "\nQuery completed (is_error: " . ($msg->is_error ? 'yes' : 'no') . ")";
            last;
        }
    }
}
catch {
    say "Error during query: $_";
};

say "\n", "-" x 50;
say "Error handling examples complete!";
