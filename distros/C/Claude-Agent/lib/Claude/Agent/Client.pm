package Claude::Agent::Client;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Future;
use Claude::Agent::Logger '$log';
use Claude::Agent::Options;
use Claude::Agent::Query;
use Claude::Agent::Message;
use Claude::Agent::Error;

BEGIN {
    Object::Proto::define('Claude::Agent::Client',
        'options:lazy:builder(_build_options)',
        'loop:predicate',
        'query_args:HashRef:default({})',
        '_query',
        '_session_id',
        '_connected:Bool:default(0)',
    );
}

sub _build_options { Claude::Agent::Options->new }

sub connect {
    my ($self, $prompt) = @_;

    Claude::Agent::Error->throw(message => 'Already connected') if $self->_connected;

    $log->debug("Client: connecting");
    $self->_start($self->options, $prompt);
    return $self;
}

sub resume {
    my ($self, $session_id, $prompt, %args) = @_;

    Claude::Agent::Error->throw(message => 'Already connected') if $self->_connected;
    Claude::Agent::Error->throw(message => 'resume needs a session id') unless defined $session_id && length $session_id;

    $log->debug(sprintf("Client: resuming session %s", $session_id));
    $self->_start($self->options->with(resume => $session_id, ($args{fork} ? (fork_session => 1) : ())), $prompt);
    $self->_session_id($session_id);
    return $self;
}

sub fork {
    my ($self, $session_id, $prompt) = @_;
    return $self->resume($session_id, $prompt, fork => 1);
}

sub _start {
    my ($self, $options, $prompt) = @_;
    $self->_query(Claude::Agent::Query->new(
        (defined $prompt ? (prompt => $prompt) : ()),
        options    => $options,
        persistent => 1,
        ($self->has_loop ? (loop => $self->loop) : ()),
        %{$self->query_args},
    ));
    $self->_connected(1);
    return;
}

sub is_connected {
    my ($self) = @_;
    return $self->_connected;
}

sub session_id {
    my ($self) = @_;
    return $self->_session_id // ($self->_query ? $self->_query->session_id : undef);
}

sub query {
    my ($self) = @_;
    return $self->_query;
}

sub _live_query {
    my ($self) = @_;
    Claude::Agent::Error->throw(message => 'Not connected') unless $self->_connected;
    Claude::Agent::Error->throw(message => 'Query not initialized') unless $self->_query;
    return $self->_query;
}

sub send {
    my ($self, $content, %args) = @_;

    my $query = $self->_live_query;
    my $session_id = $args{session_id} // 'default';
    $log->debug(sprintf("Client: sending a message on session %s", $session_id));
    Claude::Agent::Error->throw(message => 'Could not send the message: the session has ended')
        unless $query->send_user_message($content, session_id => $session_id);
    return $self;
}

sub receive {
    my ($self) = @_;

    my $msg = $self->_live_query->next;
    if ($msg && $msg->isa('Claude::Agent::Message::System')) {
        my $sid = $msg->get_session_id;
        $self->_session_id($sid) if $sid;
    }
    return $msg;
}

sub receive_async {
    my ($self) = @_;
    return $self->_live_query->next_async;
}

sub receive_until_result {
    my ($self) = @_;

    my $max_iterations = 1000;
    my $max_env = $ENV{CLAUDE_AGENT_MAX_MESSAGES};
    $max_env =~ s/^\s+|\s+$//g if defined $max_env;
    if (defined $max_env && $max_env =~ /^[1-9]\d*$/) {
        $max_iterations = $max_env > 5000 ? 5000 : $max_env;
    }

    my @messages;
    while (my $msg = $self->receive) {
        push @messages, $msg;
        last if $msg->isa('Claude::Agent::Message::Result');
        if (@messages >= $max_iterations) {
            $log->warning(sprintf("receive_until_result: stopped after %d messages without a result", $max_iterations));
            last;
        }
    }
    return wantarray ? @messages : \@messages;
}

sub disconnect {
    my ($self) = @_;

    if ($self->_query) {
        $log->debug("Client: disconnecting");
        $self->_query->close;
    }
    $self->_query(undef);
    $self->_session_id(undef);
    $self->_connected(0);
    return $self;
}

for my $method (qw(
    interrupt set_permission_mode set_model set_max_thinking_tokens rewind_files
    mcp_status get_context_usage reconnect_mcp_server toggle_mcp_server stop_task
)) {
    no strict 'refs';
    *{$method} = sub {
        my $self = shift;
        return unless $self->_connected && $self->_query;
        return $self->_query->$method(@_);
    };
    my $async = "${method}_async";
    *{$async} = sub {
        my $self = shift;
        return Future->fail('Not connected') unless $self->_connected && $self->_query;
        return $self->_query->$async(@_);
    };
}

sub server_info {
    my ($self) = @_;
    return $self->_query ? $self->_query->server_info : undef;
}

1;

__END__

=head1 NAME

Claude::Agent::Client - Multi-turn session with the Claude Code CLI

=head1 SYNOPSIS

    use Claude::Agent::Client;
    use Claude::Agent::Options;

    my $client = Claude::Agent::Client->new(
        options => Claude::Agent::Options->new(
            allowed_tools => ['Read', 'Glob', 'Grep'],
        ),
    );

    $client->connect("Help me understand this codebase");
    while (my $msg = $client->receive) {
        if ($msg->isa('Claude::Agent::Message::Result')) {
            print "Result: ", $msg->result, "\n";
            last;
        }
        elsif ($msg->isa('Claude::Agent::Message::Assistant')) {
            print "Claude: ", $msg->text, "\n";
        }
    }

    $client->send("Now find all TODO comments");
    my @turn = $client->receive_until_result;

    $client->set_permission_mode('acceptEdits');
    $client->disconnect;

=head1 DESCRIPTION

A client keeps one CLI process alive for a whole conversation. Each
C<send> writes another user message to it and each turn ends with a
L<Claude::Agent::Message::Result>. The C<session()> function of
L<Claude::Agent> builds one.

=head1 ATTRIBUTES

=head2 options

A L<Claude::Agent::Options>. Defaults to an empty one.

=head2 loop

An L<IO::Async::Loop> to run on.

=head2 query_args

Extra arguments for the L<Claude::Agent::Query> the client creates, for
tests: C<spawn>, C<writer>, C<closer>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 connect

    $client->connect($prompt);
    $client->connect;

Start the process and send the first prompt, if given. Dies when already
connected.

=head2 resume

    $client->resume($session_id, $prompt);

Start the process on an earlier session.

=head2 fork

    $client->fork($session_id, $prompt);

As C<resume>, but under a new session id.

=head2 send

    $client->send($content, session_id => $id);

Write a user message: a string or an array of content blocks. The session
id defaults to C<default>, which the CLI reads as the current session.

=head2 receive

    my $msg = $client->receive;

The next message, or undef when the process has ended.

=head2 receive_async

A L<Future> of the next message.

=head2 receive_until_result

    my @messages = $client->receive_until_result;

Every message up to and including the next result. Stops after
C<CLAUDE_AGENT_MAX_MESSAGES> messages (default 1000, at most 5000).

=head2 is_connected

True between C<connect> and C<disconnect>.

=head2 session_id

The session id, once the CLI has reported it.

=head2 query

The underlying L<Claude::Agent::Query>, or undef.

=head2 server_info

The CLI's C<initialize> response, once the query has started.

=head2 interrupt, set_permission_mode, set_model, set_max_thinking_tokens, rewind_files, mcp_status, get_context_usage, reconnect_mcp_server, toggle_mcp_server, stop_task

Delegate to the query; see L<Claude::Agent::Query>. When the client is not
connected they return undef.

=head2 interrupt_async, set_permission_mode_async, set_model_async, set_max_thinking_tokens_async, rewind_files_async, mcp_status_async, get_context_usage_async, reconnect_mcp_server_async, toggle_mcp_server_async, stop_task_async

The same, returning a L<Future>, which fails when the client is not
connected.

=head2 disconnect

    $client->disconnect;

Stop the process and forget the session. Safe to call more than once.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
