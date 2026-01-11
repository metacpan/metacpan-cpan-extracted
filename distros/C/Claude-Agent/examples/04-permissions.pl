#!/usr/bin/env perl
#
# Permissions Example
#
# This example demonstrates how to use the can_use_tool callback
# to implement custom permission logic for tool usage.
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;
use Claude::Agent::Permission;

# Track which tools have been approved this session
my %approved_tools;

# Custom permission handler
my $permission_handler = sub {
    my ($tool_name, $input, $context) = @_;

    # Always allow read-only tools
    if ($tool_name =~ /^(Read|Glob|Grep)$/) {
        return Claude::Agent::Permission->allow(
            updated_input => $input,
        );
    }

    # Check if tool was previously approved
    if ($approved_tools{$tool_name}) {
        return Claude::Agent::Permission->allow(
            updated_input => $input,
        );
    }

    # For Bash commands, check the command
    if ($tool_name eq 'Bash') {
        my $command = $input->{command} // '';

        # Auto-allow safe read-only commands
        if ($command =~ /^(ls|pwd|echo|cat|head|tail|wc|date|whoami)(\s|$)/) {
            return Claude::Agent::Permission->allow(
                updated_input => $input,
            );
        }

        # Deny dangerous commands
        if ($command =~ /rm|sudo|chmod|chown|mv|cp.*-f/) {
            return Claude::Agent::Permission->deny(
                message => "Command '$command' is not allowed for safety reasons.",
            );
        }

        # Ask for other commands (in a real app, prompt the user)
        say "\n[PERMISSION] Bash command requested: $command";
        say "[PERMISSION] Auto-approving for demo purposes...";

        $approved_tools{$tool_name} = 1;
        return Claude::Agent::Permission->allow(
            updated_input => $input,
        );
    }

    # For Write/Edit, be more careful
    if ($tool_name =~ /^(Write|Edit)$/) {
        my $file_path = $input->{file_path} // '';

        say "\n[PERMISSION] $tool_name requested for: $file_path";

        # Only allow writes to specific directories
        if ($file_path =~ m{^(/tmp/|\./)}) {
            say "[PERMISSION] Allowing write to temp/local path";
            return Claude::Agent::Permission->allow(
                updated_input => $input,
            );
        }

        say "[PERMISSION] Denying write to protected path";
        return Claude::Agent::Permission->deny(
            message => "Writes are only allowed to /tmp/ or current directory.",
        );
    }

    # Default: deny unknown tools
    return Claude::Agent::Permission->deny(
        message => "Tool '$tool_name' requires explicit approval.",
    );
};

# Configure options with permission handler
my $options = Claude::Agent::Options->new(
    allowed_tools => ['Read', 'Glob', 'Grep', 'Bash', 'Write'],
    can_use_tool  => $permission_handler,
    max_turns     => 5,
);

# Send a query
my $iter = query(
    prompt  => 'Run "date" command to show the current date and time.',
    options => $options,
);

say "Sending query with custom permissions...";
say "-" x 50;

while (my $msg = $iter->next) {
    if ($msg->isa('Claude::Agent::Message::Assistant')) {
        for my $block (@{$msg->content_blocks}) {
            if ($block->isa('Claude::Agent::Content::Text')) {
                print $block->text;
            }
            elsif ($block->isa('Claude::Agent::Content::ToolUse')) {
                say "\n[Tool: " . $block->name . "]";
            }
        }
    }
    elsif ($msg->isa('Claude::Agent::Message::Result')) {
        say "\n", "-" x 50;
        say "Completed!";
        last;
    }
}
