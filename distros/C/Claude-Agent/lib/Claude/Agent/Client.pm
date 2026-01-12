package Claude::Agent::Client;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Logger '$log';
use Types::Common -types;
use Marlin
    'options'      => sub { Claude::Agent::Options->new() },
    'loop?',                                       # Optional external IO::Async loop
    '_query==.',
    '_session_id==.',
    '_connected==' => sub { 0 };

use Claude::Agent::Options;
use Claude::Agent::Query;
use Claude::Agent::Message;
use Claude::Agent::Error;

=head1 NAME

Claude::Agent::Client - Persistent session client for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Client;
    use Claude::Agent::Options;

    my $client = Claude::Agent::Client->new(
        options => Claude::Agent::Options->new(
            allowed_tools => ['Read', 'Glob', 'Grep'],
        ),
    );

    # Start a session
    $client->connect("Help me understand this codebase");

    # Process messages until result
    while (my $msg = $client->receive) {
        if ($msg->isa('Claude::Agent::Message::Result')) {
            print "Result: ", $msg->result, "\n";
            last;
        }
        elsif ($msg->isa('Claude::Agent::Message::Assistant')) {
            print "Claude: ", $msg->text, "\n";
        }
    }

    # Send follow-up in same session
    $client->send("Now find all TODO comments");

    while (my $msg = $client->receive) {
        # ... process messages
    }

    # Disconnect when done
    $client->disconnect;

=head1 DESCRIPTION

Claude::Agent::Client provides a persistent session interface for multi-turn
conversations with Claude. Unlike the simple C<query()> function which creates
a new session for each call, the Client maintains state across multiple
interactions.

=head1 ATTRIBUTES

=head2 options

L<Claude::Agent::Options> object with configuration settings.

=head1 METHODS

=head2 connect

    $client->connect($prompt);

Start a new session with the given prompt.

=cut

## no critic (ProhibitBuiltinHomonyms)
sub connect {
    my ($self, $prompt) = @_;

    Claude::Agent::Error->throw(message => 'Already connected') if $self->_connected;

    $log->debug("Client: Connecting to Claude API");

    $self->_query(
        Claude::Agent::Query->new(
            prompt  => $prompt,
            options => $self->options,
            ($self->has_loop ? (loop => $self->loop) : ()),
        )
    );

    $self->_connected(1);
    $log->debug("Client: Connected, session started");
    return $self;
}

=head2 is_connected

    if ($client->is_connected) { ... }

Returns true if the client has an active session.

=cut

sub is_connected {
    my ($self) = @_;
    return $self->_connected;
}

=head2 session_id

    my $id = $client->session_id;

Returns the current session ID (available after first message).

=cut

sub session_id {
    my ($self) = @_;
    return $self->_session_id // ($self->_query ? $self->_query->session_id : undef);
}

=head2 receive

    my $msg = $client->receive;

Blocking call to receive the next message. Returns undef when no more messages.

=cut

sub receive {
    my ($self) = @_;

    Claude::Agent::Error->throw(message => 'Not connected') unless $self->_connected;
    Claude::Agent::Error->throw(message => 'Query not initialized') unless $self->_query;

    my $msg = $self->_query->next;

    # Capture session_id from any system message that has one
    if ($msg && $msg->isa('Claude::Agent::Message::System')) {
        my $sid = $msg->get_session_id;
        $self->_session_id($sid) if $sid;
    }

    # Result messages indicate end of current query turn
    # No additional handling needed - caller should check message type

    return $msg;
}

=head2 receive_async

    my $msg = await $client->receive_async;

Async call to receive the next message. Returns a Future.

=cut

sub receive_async {
    my ($self) = @_;

    Claude::Agent::Error->throw(message => 'Not connected') unless $self->_connected;
    Claude::Agent::Error->throw(message => 'Query not initialized') unless $self->_query;

    return $self->_query->next_async;
}

=head2 receive_until_result

    my @messages = $client->receive_until_result;

Receive all messages until a Result message is received.

=cut

sub receive_until_result {
    my ($self) = @_;

    my @messages;
    my $estimated_memory = 0;
    my $max_memory_bytes = $ENV{CLAUDE_AGENT_MAX_MEMORY_MB} ? $ENV{CLAUDE_AGENT_MAX_MEMORY_MB} * 1024 * 1024 : 500 * 1024 * 1024;  # Default 500MB
    # Default to 1000 messages - generous for typical use but prevents runaway loops.
    # For very long-running operations, set CLAUDE_AGENT_MAX_MESSAGES higher (max 5000).
    # Typical queries produce 10-100 messages; 1000 allows for complex multi-tool operations.
    #
    # MEMORY WARNING: Each message object may be 1-100KB depending on content.
    # At max (5000 messages), memory usage could reach 50MB-500MB.
    # For long-running operations, consider processing messages incrementally
    # using receive() in a loop rather than receive_until_result().
    # Set CLAUDE_AGENT_MAX_MEMORY_MB to limit memory usage (default 500MB).
    my $max_iterations = 1000;
    my $max_allowed = 5_000;  # Reduced to prevent memory exhaustion (each message ~1-100KB)
    my $max_msg_env = $ENV{CLAUDE_AGENT_MAX_MESSAGES};
    $max_msg_env =~ s/^\s+|\s+$//g if defined $max_msg_env;  # trim whitespace
    # Validate after trimming - must be positive integer > 0 (rejects 0 and leading zeros)
    if (defined $max_msg_env && $max_msg_env =~ /^[1-9]\d*$/) {
        $max_iterations = $max_msg_env;
        if ($max_iterations > $max_allowed) {
            $log->warning(sprintf("CLAUDE_AGENT_MAX_MESSAGES=%d exceeds maximum (%d), using %d. "
                . "WARNING: High message counts risk memory exhaustion (estimated %dMB-%dMB at max). "
                . "Set CLAUDE_AGENT_MAX_MEMORY_MB to limit memory, or use receive() for incremental processing.",
                $max_iterations, $max_allowed, $max_allowed, $max_allowed / 10, $max_allowed / 1));
            $max_iterations = $max_allowed;
        }
        elsif ($max_iterations > 2500) {
            $log->warning(sprintf("CLAUDE_AGENT_MAX_MESSAGES=%d may cause high memory usage (estimated %dMB-%dMB). "
                . "Consider using receive() with incremental processing or set CLAUDE_AGENT_MAX_MEMORY_MB.",
                $max_iterations, $max_iterations / 10, $max_iterations / 1));
        }
    }
    my $iterations = 0;
    # Create JSON::Lines instance once outside the loop for better performance
    require JSON::Lines;
    my $jsonl = JSON::Lines->new;
    while (my $msg = $self->receive) {
        $iterations++;
        push @messages, $msg;
        # Estimate memory usage (rough heuristic based on message content)
        # Estimate size based on raw data structure - use JSON::Lines for encoding
        my $json_str = eval { $jsonl->encode([$msg->message // {}]) } // '{}';
        $estimated_memory += length($json_str) + 500;  # Add overhead estimate
        last if $msg->isa('Claude::Agent::Message::Result');
        if ($estimated_memory >= $max_memory_bytes) {
            $log->warning(sprintf("receive_until_result: estimated memory usage (%d bytes) exceeds limit (%d bytes), breaking loop. "
                . "Set CLAUDE_AGENT_MAX_MEMORY_MB to increase limit or use incremental processing.",
                $estimated_memory, $max_memory_bytes));
            last;
        }
        if ($iterations >= $max_iterations) {
            $log->warning(sprintf("receive_until_result: processed max messages (%d), breaking loop. "
                . "Set CLAUDE_AGENT_MAX_MESSAGES to increase limit.", $max_iterations));
            last;
        }
    }
    # Check if we exited without a Result (connection dropped)
    if (@messages && !$messages[-1]->isa('Claude::Agent::Message::Result')) {
        $log->debug("receive_until_result: connection closed without Result message");
    }
    return wantarray ? @messages : \@messages;
}

=head2 send

    $client->send($message);

Send a follow-up message in the current session.

=cut

## no critic (ProhibitBuiltinHomonyms)
sub send {
    my ($self, $content) = @_;

    Claude::Agent::Error->throw(message => 'Not connected') unless $self->_connected;

    # Get session_id from previous query or stored value
    my $session_id = $self->_session_id // ($self->_query ? $self->_query->session_id : undef);
    Claude::Agent::Error->throw(message => 'No session_id available for send') unless $session_id;

    # Cleanup previous query if it exists
    if ($self->_query) {
        $self->_query->cleanup();
    }

    $log->debug(sprintf("Client: Sending follow-up, resuming session id=%s", $session_id));

    # Create new options with resume
    my $opts = $self->options;
    my $resume_opts = Claude::Agent::Options->new(
        ($opts->has_allowed_tools ? (allowed_tools => $opts->allowed_tools) : ()),
        ($opts->has_disallowed_tools ? (disallowed_tools => $opts->disallowed_tools) : ()),
        ($opts->has_model ? (model => $opts->model) : ()),
        ($opts->has_permission_mode ? (permission_mode => $opts->permission_mode) : ()),
        ($opts->has_mcp_servers ? (mcp_servers => $opts->mcp_servers) : ()),
        ($opts->has_hooks ? (hooks => $opts->hooks) : ()),
        ($opts->has_agents ? (agents => $opts->agents) : ()),
        ($opts->has_max_turns ? (max_turns => $opts->max_turns) : ()),
        ($opts->has_system_prompt ? (system_prompt => $opts->system_prompt) : ()),
        resume => $session_id,
    );

    # Create new query with resume
    $self->_query(
        Claude::Agent::Query->new(
            prompt  => $content,
            options => $resume_opts,
            ($self->has_loop ? (loop => $self->loop) : ()),
        )
    );

    return $self;
}

=head2 interrupt

    $client->interrupt;

Send an interrupt signal to abort the current operation.

=cut

sub interrupt {
    my ($self) = @_;

    return unless $self->_connected && $self->_query;
    $self->_query->interrupt;
    return $self;
}

=head2 disconnect

    $client->disconnect;

End the current session.

=cut

sub disconnect {
    my ($self) = @_;

    $log->debug("Client: Disconnected");
    $self->_query(undef);
    $self->_session_id(undef);
    $self->_connected(0);
    return $self;
}

=head2 resume

    $client->resume($session_id, $prompt);

Resume a previous session.

=cut

sub resume {
    my ($self, $session_id, $prompt) = @_;

    Claude::Agent::Error->throw(message => 'Already connected') if $self->_connected;

    # Create new options with resume, preserving all relevant options
    my $opts = $self->options;
    my $resume_opts = Claude::Agent::Options->new(
        ($opts->has_allowed_tools ? (allowed_tools => $opts->allowed_tools) : ()),
        ($opts->has_model ? (model => $opts->model) : ()),
        ($opts->has_permission_mode ? (permission_mode => $opts->permission_mode) : ()),
        ($opts->has_mcp_servers ? (mcp_servers => $opts->mcp_servers) : ()),
        ($opts->has_hooks ? (hooks => $opts->hooks) : ()),
        ($opts->has_agents ? (agents => $opts->agents) : ()),
        ($opts->has_max_turns ? (max_turns => $opts->max_turns) : ()),
        ($opts->has_system_prompt ? (system_prompt => $opts->system_prompt) : ()),
        resume => $session_id,
    );

    $log->debug(sprintf("Client: Resuming session id=%s", $session_id));

    $self->_query(
        Claude::Agent::Query->new(
            prompt  => $prompt,
            options => $resume_opts,
            ($self->has_loop ? (loop => $self->loop) : ()),
        )
    );

    $self->_session_id($session_id);
    $self->_connected(1);
    $log->debug(sprintf("Client: Session resumed id=%s", $session_id));
    return $self;
}

1;

__END__

=head1 EXAMPLE: INTERACTIVE SESSION

    use Claude::Agent::Client;
    use Claude::Agent::Options;

    my $client = Claude::Agent::Client->new(
        options => Claude::Agent::Options->new(
            allowed_tools   => ['Read', 'Glob', 'Grep', 'Edit'],
            permission_mode => 'acceptEdits',
        ),
    );

    # Interactive loop
    print "Enter your first prompt: ";
    while (my $input = <STDIN>) {
        chomp $input;
        last if $input eq 'quit';

        if ($client->is_connected) {
            $client->send($input);
        } else {
            $client->connect($input);
        }

        # Process response
        for my $msg ($client->receive_until_result) {
            if ($msg->isa('Claude::Agent::Message::Assistant')) {
                print "Claude: ", $msg->text, "\n\n";
            }
            elsif ($msg->isa('Claude::Agent::Message::Result')) {
                print "--- End of turn ---\n";
            }
        }

        print "Your turn: ";
    }

    $client->disconnect;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
