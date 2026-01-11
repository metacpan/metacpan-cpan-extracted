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

    $self->_query(
        Claude::Agent::Query->new(
            prompt  => $prompt,
            options => $self->options,
            ($self->has_loop ? (loop => $self->loop) : ()),
        )
    );

    $self->_connected(1);
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
    # Default to 1000 messages - generous for typical use but prevents runaway loops.
    # For very long-running operations, set CLAUDE_AGENT_MAX_MESSAGES higher (max 100000).
    # Typical queries produce 10-100 messages; 1000 allows for complex multi-tool operations.
    my $max_iterations = 1000;
    my $max_allowed = 100_000;  # Hard cap to prevent unbounded resource consumption
    if (defined $ENV{CLAUDE_AGENT_MAX_MESSAGES} && $ENV{CLAUDE_AGENT_MAX_MESSAGES} =~ /^\d+$/ && $ENV{CLAUDE_AGENT_MAX_MESSAGES} > 0) {
        $max_iterations = $ENV{CLAUDE_AGENT_MAX_MESSAGES};
        if ($max_iterations > $max_allowed) {
            $log->warning("CLAUDE_AGENT_MAX_MESSAGES=%d exceeds maximum (%d), using %d",
                $max_iterations, $max_allowed, $max_allowed);
            $max_iterations = $max_allowed;
        }
    }
    my $iterations = 0;
    while (my $msg = $self->receive) {
        $iterations++;
        push @messages, $msg;
        last if $msg->isa('Claude::Agent::Message::Result');
        if ($iterations >= $max_iterations) {
            $log->warning("receive_until_result: processed max messages (%d), breaking loop. "
                . "Set CLAUDE_AGENT_MAX_MESSAGES to increase limit.", $max_iterations);
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
    Claude::Agent::Error->throw(message => 'No active query') unless $self->_query;
    # Note: We intentionally do NOT pre-check is_finished here due to race conditions.
    # The try/catch block below handles the case where query finishes between any
    # check and the actual write operation, providing robust error handling.

    # Attempt to send the message, catching write errors gracefully
    require Try::Tiny;
    my $write_error;
    my $original_exception;
    Try::Tiny::try {
        $self->_query->send_user_message($content);
    }
    Try::Tiny::catch {
        $original_exception = $_;
        # Stringify for logging but preserve original for re-throw
        $write_error = ref($_) ? "$_" : $_;
        $log->debug("Client::send write error: %s", $write_error);
    };

    # If write failed and query is now finished, throw appropriate error
    if ($write_error) {
        if ($self->_query->is_finished) {
            Claude::Agent::Error->throw(message => 'Query finished during send');
        }
        # Re-throw original exception if it's an object to preserve stack trace and type
        # Otherwise create a new error with the message
        if (ref($original_exception) && $original_exception->can('throw')) {
            $original_exception->throw();
        }
        Claude::Agent::Error->throw(
            message => "Send failed: $write_error",
            ($original_exception ? (cause => $original_exception) : ()),
        );
    }

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

    $self->_query(
        Claude::Agent::Query->new(
            prompt  => $prompt,
            options => $resume_opts,
            ($self->has_loop ? (loop => $self->loop) : ()),
        )
    );

    $self->_session_id($session_id);
    $self->_connected(1);
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
