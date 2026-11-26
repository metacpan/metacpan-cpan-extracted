#!/usr/bin/env perl
# A shared counter: every browser that joins "counter:<name>" sees the same
# number and the log of who changed it.
#
#   BOARDSTREAMS_PG=postgresql://user@host/db perl examples/counter.pl daemon
use v5.44;
use Mojolicious::Lite -signatures;
use Future::AsyncAwait future_class => 'Mojo::Promise';
use Mojo::Pg;

my $pg = Mojo::Pg->new($ENV{BOARDSTREAMS_PG} // die "Set BOARDSTREAMS_PG to a PostgreSQL connection string\n");
$pg->search_path([$ENV{BOARDSTREAMS_SCHEMA}]) if $ENV{BOARDSTREAMS_SCHEMA};

my $hub = plugin BoardStreams => {
    pg => $pg,
    ($ENV{BOARDSTREAMS_HEARTBEAT} ? (heartbeat_interval => $ENV{BOARDSTREAMS_HEARTBEAT}) : ()),
    # Who a connection belongs to. A real application would take this from
    # the session; here the browser just says so in the URL.
    identify => sub ($c) { $c->param('user') },
};

$hub->channel('counter:*',
    initial_state => { n => 0, log => [] },
    join          => sub ($ctx) {
        $ctx->reject('members_only', { hint => 'ask an admin' }) if $ctx->channel eq 'counter:private';
        return 1;
    },
    actions => {
        wave => sub ($ctx, $payload) { $ctx->emit(waved => $payload) },
    },
    requests => {
        add => async sub ($ctx, $payload) {
            my $by = $payload->{by} // 1;
            $ctx->reject('too_big', { max => 10 }) if abs $by > 10;
            my $n;
            await $ctx->update(sub ($u) {
                $n = $u->state->{n} += $by;
                push $u->state->{log}->@*, $by;
                $u->emit(added => { by => $by });
            });
            return { n => $n };
        },
        # Answers only when the test is over, to have an unanswered request.
        slow => sub ($ctx, $payload) { Mojo::Promise->timer(30) },
        # A real application would check who is asking before doing these.
        kick => async sub ($ctx, $payload) {
            await $ctx->hub->kick($payload->{user}, $ctx->channel, 'kicked', { by => $ctx->user });
            return undef;
        },
        empty => async sub ($ctx, $payload) {
            await $ctx->hub->kick_all($payload->{channel} // $ctx->channel, 'emptied', { by => $ctx->user });
            return undef;
        },
        ban => async sub ($ctx, $payload) {
            await $ctx->hub->disconnect($payload->{user}, 'banned', { by => $ctx->user });
            return undef;
        },
    },
);

app->start;
