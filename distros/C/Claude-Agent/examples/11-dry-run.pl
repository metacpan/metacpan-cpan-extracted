#!/usr/bin/env perl
#
# Dry-Run Mode Example
#
# This example demonstrates how to use dry-run mode to preview
# what changes Claude would make without actually executing them.
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;

# Track all changes that would be made
my @pending_changes;

# Configure options with dry-run mode enabled
my $options = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob', 'Grep', 'Edit', 'Write', 'Bash'],
    permission_mode => 'bypassPermissions',
    max_turns       => 10,
    dry_run         => 1,
    on_dry_run      => sub {
        my ($tool_name, $tool_input, $preview) = @_;
        push @pending_changes, {
            tool    => $tool_name,
            input   => $tool_input,
            preview => $preview,
        };
        say "[DRY-RUN] $preview";
    },
);

# Send a query that would normally make changes
my $iter = query(
    prompt  => 'Read the file lib/Claude/Agent.pm and then create a simple test file at /tmp/test-dry-run.txt with the text "Hello from dry-run test"',
    options => $options,
);

say "Running in DRY-RUN mode...";
say "Read operations will execute, writes will be previewed.";
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
        last;
    }
}

say "\n", "-" x 50;
say "DRY-RUN SUMMARY";
say "-" x 50;

if (@pending_changes) {
    say "The following " . scalar(@pending_changes) . " change(s) would be made:\n";
    for my $i (0 .. $#pending_changes) {
        my $change = $pending_changes[$i];
        say sprintf("%d. [%s] %s", $i + 1, $change->{tool}, $change->{preview});
    }
    say "\nTo apply these changes, run again without dry_run => 1";
}
else {
    say "No write operations were requested.";
}
