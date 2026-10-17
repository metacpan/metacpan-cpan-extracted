#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;

# Print the model's text as it streams, using include_partial_messages
# and the StreamEvent messages it produces, and show every hook
# lifecycle event with include_hook_events.

use Claude::Agent qw(query);
use Claude::Agent::Options;

$| = 1;

my $iter = query(
    prompt  => 'Explain in three sentences what this directory contains.',
    options => Claude::Agent::Options->new(
        allowed_tools            => ['Read', 'Glob'],
        permission_mode          => 'bypassPermissions',
        include_partial_messages => 1,
        include_hook_events      => 1,
        max_turns                => 3,
    ),
);

while (my $msg = $iter->next) {
    if ($msg->isa('Claude::Agent::Message::StreamEvent')) {
        my $delta = $msg->text_delta;
        print $delta if defined $delta;
        print "\n" if $msg->event_type eq 'message_stop';
    }
    elsif ($msg->isa('Claude::Agent::Message::HookEvent')) {
        say "[hook ", $msg->subtype, "] ", $msg->hook_event_name // '';
    }
    elsif ($msg->isa('Claude::Agent::Message::RateLimitEvent')) {
        say "[rate limit] ", $msg->status // '';
    }
    elsif ($msg->isa('Claude::Agent::Message::Result')) {
        say "Done in ", $msg->duration_ms // '?', " ms, cost \$", $msg->total_cost_usd // '?';
        last;
    }
}
