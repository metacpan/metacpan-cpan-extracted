#!/usr/bin/env perl
#
# Async Hooks Example
#
# This example demonstrates how to use asynchronous Perl hook callbacks
# for operations that require I/O, such as:
# - HTTP requests to external validation services
# - Database lookups for permission checks
# - Async logging or metrics collection
#
# Hooks can return either:
# - A hashref (synchronous, backward compatible)
# - A Future that resolves to a hashref (asynchronous)
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;
use Claude::Agent::Hook::Matcher;
use Claude::Agent::Hook::Result;
use Future;

# Simulated async permission service
# In a real app, this might call an HTTP API or query a database
sub check_permission_async {
    my ($loop, $tool_name, $user_id) = @_;

    # Simulate async latency
    return $loop->delay_future(after => 0.1)->then(sub {
        # Simulate permission logic
        my $allowed = $tool_name ne 'Bash';  # Block Bash for demo
        return Future->done({
            allowed => $allowed,
            reason  => $allowed ? 'Permission granted' : 'Bash commands require approval',
        });
    });
}

# Simulated async audit logging
sub log_tool_use_async {
    my ($loop, $tool_name, $tool_input) = @_;

    return $loop->delay_future(after => 0.05)->then(sub {
        # In a real app, this might write to a database or send to a log service
        my $timestamp = localtime();
        say "  [AUDIT $timestamp] Tool: $tool_name";
        return Future->done(1);
    });
}

# Define async PreToolUse hooks
my $pre_tool_hooks = [
    # Async permission check hook
    Claude::Agent::Hook::Matcher->new(
        hooks => [sub {
            my ($input, $tool_use_id, $context, $loop) = @_;
            my $tool_name = $input->{tool_name};

            # If we have a loop, use async permission check
            if ($loop) {
                say "[HOOK] Checking permissions asynchronously for: $tool_name";

                return check_permission_async($loop, $tool_name, 'demo-user')->then(sub {
                    my ($result) = @_;

                    if ($result->{allowed}) {
                        say "[HOOK] Permission granted for: $tool_name";
                        return Future->done(Claude::Agent::Hook::Result->proceed());
                    } else {
                        say "[HOOK] Permission DENIED for: $tool_name - $result->{reason}";
                        return Future->done(Claude::Agent::Hook::Result->deny(
                            reason => $result->{reason},
                        ));
                    }
                });
            }

            # Fallback to sync if no loop
            say "[HOOK] (sync fallback) Allowing: $tool_name";
            return Claude::Agent::Hook::Result->proceed();
        }],
    ),

    # Async audit logging hook (non-blocking)
    Claude::Agent::Hook::Matcher->new(
        hooks => [sub {
            my ($input, $tool_use_id, $context, $loop) = @_;
            my $tool_name = $input->{tool_name};
            my $tool_input = $input->{tool_input};

            if ($loop) {
                # Start async logging but don't wait for it
                # We return proceed immediately, logging happens in background
                return log_tool_use_async($loop, $tool_name, $tool_input)->then(sub {
                    return Future->done(Claude::Agent::Hook::Result->proceed());
                });
            }

            return Claude::Agent::Hook::Result->proceed();
        }],
    ),
];

# Define async PostToolUse hooks (these are fire-and-forget)
my $post_tool_hooks = [
    Claude::Agent::Hook::Matcher->new(
        hooks => [sub {
            my ($input, $tool_use_id, $context, $loop) = @_;
            my $tool_name = $input->{tool_name};
            my $tool_result = $input->{tool_result};

            if ($loop) {
                # Async post-processing (e.g., analyze results, update metrics)
                return $loop->delay_future(after => 0.05)->then(sub {
                    say "  [POST-HOOK] Async post-processing completed for: $tool_name";
                    return Future->done(Claude::Agent::Hook::Result->proceed());
                });
            }

            say "  [POST-HOOK] Tool completed: $tool_name";
            return Claude::Agent::Hook::Result->proceed();
        }],
    ),
];

# Example: Rate limiting hook with async counter
my $rate_limit_hooks = [
    Claude::Agent::Hook::Matcher->new(
        matcher => 'Grep',  # Only apply to Grep tool
        hooks   => [sub {
            my ($input, $tool_use_id, $context, $loop) = @_;

            if ($loop) {
                # Simulate async rate limit check
                return $loop->delay_future(after => 0.02)->then(sub {
                    # In real app: check Redis/DB for rate limit
                    state $grep_count = 0;
                    $grep_count++;

                    if ($grep_count > 10) {
                        return Future->done(Claude::Agent::Hook::Result->deny(
                            reason => 'Rate limit exceeded for Grep tool',
                        ));
                    }

                    say "  [RATE-LIMIT] Grep calls: $grep_count/10";
                    return Future->done(Claude::Agent::Hook::Result->proceed());
                });
            }

            return Claude::Agent::Hook::Result->proceed();
        }],
    ),
];

# Configure options with async hooks
my $options = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob', 'Grep'],  # Only read-only tools
    permission_mode => 'bypassPermissions',
    max_turns       => 5,
    hooks           => {
        PreToolUse  => [@$pre_tool_hooks, @$rate_limit_hooks],
        PostToolUse => $post_tool_hooks,
    },
);

say "Async Hooks Example";
say "=" x 60;
say "This example demonstrates:";
say "  - Async permission checks (simulated API call)";
say "  - Async audit logging";
say "  - Async rate limiting for specific tools";
say "  - Async post-tool-use processing";
say "";
say "Sending query with async Perl hooks...";
say "-" x 60;

my $iter = query(
    prompt  => 'Use Glob to find all .pm files in lib/, then use Grep to search for "sub " in one of them.',
    options => $options,
);

while (my $msg = $iter->next) {
    if ($msg->isa('Claude::Agent::Message::Assistant')) {
        for my $block (@{$msg->content_blocks}) {
            if ($block->isa('Claude::Agent::Content::Text')) {
                print $block->text;
            }
            elsif ($block->isa('Claude::Agent::Content::ToolUse')) {
                say "\n[Calling: " . $block->name . "]";
            }
        }
    }
    elsif ($msg->isa('Claude::Agent::Message::Result')) {
        say "\n" . "-" x 60;
        say "Completed!";
        last;
    }
}
