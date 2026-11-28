package BoardStreams;
use v5.44;

our $VERSION = "v0.0.60";

# The version of the protocol spoken between server and client: the
# messages that travel over the WebSocket and what they mean. A server and
# a client work together when, and only when, this number is the same on
# both sides, whatever the versions of the libraries themselves.
#
# RULE: add one to it in every release that makes the protocol
# incompatible with earlier releases of either library, and make the same
# change to PROTOCOL_VERSION in the JavaScript client (src/index.ts).
# Leave it alone otherwise, including when the change is one that both
# older servers and older clients keep working with.
use constant PROTOCOL_VERSION => 2;

1;
__END__

=encoding utf-8

=head1 NAME

BoardStreams - WebSocket channels for Mojolicious whose events and state survive disconnections

=head1 SYNOPSIS

    use Mojolicious::Lite -signatures;
    use Future::AsyncAwait future_class => 'Mojo::Promise';

    my $hub = plugin BoardStreams => { pg => 'postgresql://user@host/db' };

    $hub->channel('counter:*',
        initial_state => { n => 0 },
        join          => sub ($ctx) { 1 },
        requests      => {
            add => async sub ($ctx, $payload) {
                await $ctx->update(sub ($u) {
                    $u->state->{n} += $payload->{by};
                    $u->emit(added => $payload);
                });
                return 'thanks';
            },
        },
    );

    # anywhere else in the application
    $c->boardstreams->emit('counter:lobby', 'announcement', { text => 'hi' });

    app->start;

=head1 TUTORIAL

This distribution comes with a step-by-step tutorial, F<TUTORIAL.md>, in its
top-level directory. It builds a small chat application and covers both
the server and the browser side: channels, state, events, actions and
requests, the JavaScript client, and what happens during disconnections.

Because it is a Markdown file, it is not listed among the documentation on
MetaCPAN. Find it by browsing the files of the release there, in the
unpacked distribution, or in the source repository at
L<https://codeberg.org/gandalf/boardstreams-perl>.

=head1 DESCRIPTION

Browsers join channels over one WebSocket (served at C</boardstreams> by
default) with the C<boardstreams> npm package, and Perl programs with
L<BoardStreams::Client>. They send actions and
requests; only the server emits events and changes a channel's state.

Every change gets a per-channel sequence number and is stored in PostgreSQL
together with its events, in one transaction. A browser that reconnects says
which number it saw last and is sent what it missed, or the whole state if
that history has been purged (C<retention> option, in seconds; default one
hour). Actions and requests carry a unique id, so one that is resent after a
reconnection takes effect once.

The clients and this distribution work together when they speak the same
version of the BoardStreams protocol. That is a number of its own
(C<BoardStreams::PROTOCOL_VERSION>, currently 2), which only goes up when a
release makes the protocol incompatible with earlier ones. The server
announces it on each connection, and a client that speaks another refuses
to go on. The version numbers of the libraries do not have to match.

See F<examples/counter.pl> for a complete application.

=head1 OPTIONS

    plugin BoardStreams => { pg => $pg, retention => 86400 };

=over

=item pg

Required. A PostgreSQL connection string or a L<Mojo::Pg> object.

=item route

Path of the WebSocket route. Defaults to C</boardstreams>.

=item routes

Route object to attach that route to, for example one behind an C<under>
that lets only some clients connect. Defaults to the application's routes.
The C<under> may answer at once or later (returning C<undef> and calling
C<< $c->continue >> when it knows). Headers that it sets on C<< $c->res >> are sent
with the answer to the WebSocket handshake, where a client such as
L<BoardStreams::Client> can check them.

=item retention

Seconds that event history and request ids are kept. Defaults to 3600.

=item heartbeat_interval

Seconds between heartbeats to each browser. Defaults to 25.

=item retry_delay

Seconds between retries while PostgreSQL is unreachable. Defaults to 1.

=item listener_check_interval

Seconds between checks that this process still receives PostgreSQL
notifications; see L</LOSING POSTGRESQL>. Defaults to 5.

=item lazy_migrate

By default the plugin creates its tables (C<bs_channel>, C<bs_event>,
C<bs_request> and C<bs_floor>) when it is loaded. If this option is true, it does not touch
the database until the tables are first needed: when a browser joins a
channel, or when C<update>, C<emit> or C<snapshot> is called.

=item identify

A sub that receives the WebSocket's controller when a browser connects and
returns who the connection belongs to, for example
C<< sub ($c) { $c->session('user_id') } >>. Needed for C<kick> and
C<disconnect> by user; see L</KICKING AND DISCONNECTING>.

=back

=head1 KICKING AND DISCONNECTING

    $c->boardstreams->kick($user, 'chat:lobby', 'spam', { strikes => 3 });
    $c->boardstreams->disconnect($user, 'banned');
    $c->boardstreams->kick_all('chat:lobby', 'closing_time');

C<kick> removes all of a user's browsers from one channel; C<disconnect>
closes all of the user's connections, and the JavaScript client does not
reconnect after it. Both work across server processes and return promises.
The reason (default C<kicked> and C<disconnected>) and the optional data
reach the browser as the error that the channel's pending requests are
rejected with. Users are told apart by the C<identify> option.

C<kick_all> removes every member from a channel, whoever they are, and each
browser experiences it as a C<kick>. The channel keeps its state and
history.

Inside a handler, C<< $ctx->kick($reason, $data) >> and
C<< $ctx->disconnect($reason, $data) >> do the same to just the browser
being served, and C<< $ctx->user >> is that browser's identity.

Neither is a ban: a browser can ask to join again or the user can reload
the page, and it is the C<join> handler that decides whether to let them in.

=head1 STOPPING

When the server is stopped gracefully (the C<QUIT> signal, a hypnotoad hot
deployment, a worker reaching its C<accepts> limit), the plugin closes its
WebSocket connections at once, so that the process does not wait for them
until C<graceful_timeout>. Clients treat this as an ordinary lost
connection: they reconnect to whichever process answers and catch up. See
"Stopping and deploying" in the tutorial, which has a note for Docker.

=head1 UPGRADING

The tables are upgraded automatically by the first process of a new version
that needs them. Upgrade all server processes together: a process announces
the schema version it works with, and a process still running code that
only knows an older one retires itself when it hears that. It closes its
WebSocket connections, refuses new ones and makes C<update>, C<emit> and
C<snapshot> fail, until it is restarted with the new code.

Applications that keep their BoardStreams tables in different PostgreSQL
schemas of one database do not affect each other.

=head1 DELETING A CHANNEL

    $c->boardstreams->delete_channel('chat:old-room', 'archived');

Deletes a channel's state together with its event history and recorded
request ids, which reference the channel's row and go with it. Every
member, on all server processes, is removed and told so, as with
C<kick_all>; the reason defaults to C<deleted>. Returns a promise of
whether there was anything to delete. A channel that is used again
afterwards starts afresh from its initial state.

Sequence numbers of deleted channels are never reused: a new channel starts
above the highest number that any deleted channel reached. A browser that
returns with a position in a deleted channel is therefore recognised as out
of date and given the fresh state, flagged as a gap.

Deleting the row from C<bs_channel> with plain SQL has the same effect on
the tables, but members are not told until the channel's next update.

=head1 LOSING POSTGRESQL

Updates, kicks and disconnects reach a server process as PostgreSQL
notifications. A process that cannot receive them serves nobody: it closes
all its WebSocket connections (close code 1013) and refuses new ones until
it hears PostgreSQL again. The browsers reconnect by themselves, rejoin,
which runs the C<join> handlers again, and are sent what they missed.

A process notices a closed PostgreSQL connection at once. To notice one
that died silently, it sends itself a notification every
C<listener_check_interval> seconds and treats one that fails to arrive by
the next check as a lost connection.

=head1 CHANNEL PATTERNS

The first argument of C<channel> is a channel name, or a pattern containing
C<*>. A C<*> stands for any run of characters other than a colon, possibly
none: C<chat:*> covers C<chat:lobby> and C<chat:> but not C<chat:eu:lobby>,
which needs C<chat:*:*>. A C<**> stands for any run of characters at all,
colons included, so C<chat:**> covers all three. Both can appear anywhere
and more than once; every other character is literal.

If several patterns cover a name, the most specific wins: an exact name,
then the pattern with the most literal characters, then the one with the
fewest C<**>, then the one registered first.

=head1 HANDLERS

Handlers given to C<channel> receive a L<BoardStreams::Context> and may be
async. C<join> accepts by returning true; C<< $ctx->reject($reason, $data) >>
refuses a join or fails a request with something the browser can read. It
runs again every time a browser rejoins. C<< $ctx->c >> is the WebSocket's
controller, for sessions and the like.

C<< $ctx->update(sub ($u) { ... }) >> and C<< $hub->update($channel, sub ($u) { ... }) >>
change C<< $u->state >> and queue events with C<< $u->emit($name, $payload) >>.

=head1 AUTHOR

Alexander Karelas E<lt>alex.karelas@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
