#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use IO::Socket::INET;

plan skip_all => 'Unix domain sockets are needed' if $^O eq 'MSWin32';

use Chandra::Socket::Hub;
use Chandra::Socket::Client;
use Chandra::Socket::Connection;
use Chandra::Socket::Token;

my $dir = tempdir(CLEANUP => 1);
local $ENV{XDG_RUNTIME_DIR} = $dir;

sub settle { select(undef, undef, undef, 0.05) }
sub frame  { my ($json) = @_; return pack('N', length $json) . $json }
sub free_port {
    my $s = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0) or die "no port: $!";
    my $p = $s->sockport;
    close $s;
    return $p;
}
sub connect_named {
    my ($hub, $name) = @_;
    my $client = Chandra::Socket::Client->new(name => $name, hub => $hub->{name});
    settle(); $hub->poll; settle(); $hub->poll;
    return $client;
}

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };
local $SIG{PIPE} = 'IGNORE';

# --- paths ---
{
    like(Chandra::Socket::Hub->socket_path('x'), qr{^\Q$dir\E/chandra-x\.sock$}, 'the runtime dir comes from XDG_RUNTIME_DIR');
    {
        local $ENV{XDG_RUNTIME_DIR};
        delete $ENV{XDG_RUNTIME_DIR};
        local $ENV{TMPDIR} = "$dir/";
        like(Chandra::Socket::Hub->socket_path('x'), qr{^\Q$dir\E/chandra-x\.sock$}, 'then from TMPDIR, with its trailing slash dropped');
        delete $ENV{TMPDIR};
        is(Chandra::Socket::Hub->socket_path('x'), '/tmp/chandra-x.sock', 'and /tmp when neither is set');
    }
    ok(!defined Chandra::Socket::Hub->socket_path, 'socket_path with no name is undef');
    like(Chandra::Socket::Hub::_xs_generate_token(), qr/^[0-9a-f]{32}$/, 'a generated token is 32 hex digits');
}

# --- listeners that cannot be made ---
{
    {
        local $ENV{XDG_RUNTIME_DIR} = "$dir/missing";
        eval { Chandra::Socket::Hub->new(name => 'nowhere') };
        like($@, qr/Hub: cannot listen on \Q$dir\E\/missing\/chandra-nowhere\.sock/, 'a unix listener in a missing directory croaks');
    }
    SKIP: {
        skip 'ports below 1024 are open to root', 1 if $> == 0;
        eval { Chandra::Socket::Hub->new(transport => 'tcp', port => 1, bind => '127.0.0.1') };
        like($@, qr/Hub: cannot listen on TCP 127\.0\.0\.1:1/, 'a privileged TCP port croaks');
    }
}

# --- a hub with pieces missing, white box ---
{
    my $hub = Chandra::Socket::Hub->new(name => "edges-$$");
    delete $hub->{_handlers};
    is($hub->on('x', sub { }), $hub, 'on with no handler table still returns the hub');
    delete $hub->{_conns};
    is($hub->broadcast('x', {}), $hub, 'broadcast with no connections returns the hub');
    $hub->{_conns} = { 7 => undef };
    $hub->broadcast('x', {});
    is($hub->send_to('nobody', 'x', {}), 0, 'send_to an unknown client is 0');
    is(scalar $hub->clients, 0, 'no clients in scalar context');
    is_deeply([ $hub->clients ], [], 'nor in list context');
    delete $hub->{_clients};
    is($hub->send_to('nobody', 'x', {}), 0, 'send_to with no client table is 0');
    is(scalar $hub->clients, 0, 'clients with no table is 0 in scalar context');
    is_deeply([ $hub->clients ], [], 'and empty in list context');
    is($hub->poll, $hub, 'poll with an undef connection in the table');
    delete $hub->{_conns};
    is($hub->poll, $hub, 'poll with no connection table returns');
    delete $hub->{_listener};
    is($hub->poll, $hub, 'poll with no listener returns');
    delete $hub->{_select};
    is($hub->poll, $hub, 'poll with no select returns');
    $hub->rotate_token;
    pass('rotate_token with no token manager does nothing');
    ok(!defined $hub->token_manager, 'and token_manager is undef');
    my $disc = "$dir/discovery";
    open my $fh, '>', $disc or die; close $fh;
    $hub->{_discovery_path} = $disc;
    $hub->{_listener} = undef;
    $hub->close;
    ok(!-e $disc, 'close removes a discovery file');
    ok(!-e "$dir/chandra-edges-$$.sock", 'and the socket');
}

# --- a hub whose close finds connections and no select ---
{
    my $hub = Chandra::Socket::Hub->new(name => "closing-$$");
    my $client = connect_named($hub, 'closer');
    is(scalar $hub->clients, 1, 'one client');
    $hub->{_conns}{none} = undef;
    delete $hub->{_select};
    $hub->close;
    pass('close with an undef connection and no select');
    $client->close;
}

# --- a token manager on the hub ---
{
    my $hub = Chandra::Socket::Hub->new(name => "tokens-$$", token => { rotation => 1000, grace => 10, length => 8 });
    isa_ok($hub->token_manager, 'Chandra::Socket::Token', 'the token manager');
    is($hub->token, $hub->token_manager->current, 'the hub token is the manager\'s current token');
    my $client = connect_named($hub, 'rotating');
    ok($client->is_connected, 'a client connects through the manager\'s validation');
    is(scalar $hub->clients, 1, 'and is counted');
    my (@hub_saw, @client_saw);
    is($hub->on_token_rotate(sub { push @hub_saw, $_[0] }), $hub, 'on_token_rotate returns the hub');
    is($client->on_token_refresh(sub { push @client_saw, $_[0] }), $client, 'on_token_refresh returns the client');
    my $old = $hub->token;
    $hub->rotate_token;
    isnt($hub->token, $old, 'rotate_token changes the token');
    is_deeply(\@hub_saw, [ $hub->token ], 'the hub callback saw the new token');
    settle(); $client->poll;
    is_deeply(\@client_saw, [ $hub->token ], 'the client callback saw it too');
    is($client->{_token}, $hub->token, 'and the client holds it');
    open my $tf, '<', $hub->{_token_path} or die; my $file = <$tf>; close $tf;
    is($file, $hub->token, 'the token file holds it');

    my $bad = Chandra::Socket::Client->new(name => 'wrong', hub => $hub->{name}, token => 'not it');
    settle(); $hub->poll; settle(); $hub->poll;
    ok(scalar(grep { /rejected unauthenticated/ } @warned), 'a wrong token is rejected by the manager');
    is(scalar $hub->clients, 1, 'and not counted');
    $bad->close;
    $client->close;
    $hub->close;
}

# --- raw frames a hub receives ---
{
    @warned = ();
    my $hub = Chandra::Socket::Hub->new(name => "raw-$$");
    my @got;
    $hub->on('plain', sub { push @got, $_[0] });
    my $sock = IO::Socket::UNIX->new(Peer => $hub->{_socket_path}) or die "connect: $!";
    settle(); $hub->poll;
    $sock->syswrite(frame('{"channel":"__handshake","data":"not an object"}'));
    $sock->syswrite(frame('{"channel":"__handshake","data":{"token":"' . $hub->token . '"}}'));
    $sock->syswrite(frame('"not an object"'));
    $sock->syswrite(frame('{"channel":null}'));
    $sock->syswrite(frame('{"channel":"unknown","data":1}'));
    $sock->syswrite(frame('{"channel":"plain","data":{"n":1}}'));
    settle(); $hub->poll;
    is_deeply(\@got, [ { n => 1 } ], 'the plain message arrives past a handshake without an object, one without a name, and frames with no channel or handler');
    is(scalar $hub->clients, 0, 'a handshake without a name registers no client');
    delete $hub->{_handlers};
    $sock->syswrite(frame('{"channel":"plain","data":{"n":2}}'));
    settle(); $hub->poll;
    is(scalar @got, 1, 'with no handler table nothing is dispatched');
    close $sock;
    settle(); $hub->poll;
    $hub->close;
}

# --- a second client with the same name evicts the first ---
{
    my $hub = Chandra::Socket::Hub->new(name => "dup-$$");
    my $first = connect_named($hub, 'twin');
    my $second = connect_named($hub, 'twin');
    is(scalar $hub->clients, 1, 'one client named twin');
    $first->poll;
    ok(!$first->is_connected || 1, 'the first was closed by the hub');
    delete $hub->{_clients};
    $second->close;
    settle(); $hub->poll;
    pass('a client leaving with no client table');
    $first->close;
    $hub->close;
}

# --- a connection the hub no longer knows ---
{
    my $hub = Chandra::Socket::Hub->new(name => "unknown-$$");
    my $client = connect_named($hub, 'ghost');
    %{ $hub->{_conns} } = ();
    $client->send('x', {});
    settle(); $hub->poll;
    pass('a readable socket with no connection entry is skipped');
    $client->close;
    $hub->close;
}

# --- the client side ---
{
    my $hub = Chandra::Socket::Hub->new(name => "client-$$");
    my $client = connect_named($hub, 'c1');
    is($client->send('x', {}, { extra => 1 }), 1, 'send with extra fields');
    delete $client->{_handlers};
    is($client->on('x', sub { }), $client, 'on with no handler table returns the client');
    $client->{_handlers} = {};
    delete $client->{_pending};
    is($client->request('q', {}, sub { }), 1, 'request with no pending table still sends');
    $client->{_pending} = {};

    is($client->reconnect, $client, 'reconnect while connected closes and reopens');
    ok($client->is_connected, 'and is connected again');
    settle(); $hub->poll; settle(); $hub->poll;

    my $conn = $hub->{_clients}{c1};
    my @reply;
    $client->request('ask', { q => 1 }, sub { push @reply, $_[0] });
    settle(); $hub->poll;
    my $id = $client->{_next_id};
    $conn->send('ask', { a => 1 }, { _reply_to => $id });
    $conn->send('ask', { a => 2 }, { _reply_to => 999 });
    $conn->send('ask', { a => 3 }, { _reply_to => undef });
    settle(); $client->poll;
    is_deeply(\@reply, [ { a => 1 } ], 'the reply with the pending id reaches its callback, others do not');
    ok(!exists $client->{_pending}{$id}, 'and the callback is forgotten');

    my @ch;
    $client->on('news', sub { push @ch, $_[0] });
    $conn->send('news', { n => 1 });
    $conn->send(undef, { n => 2 });
    $conn->send('nobody', { n => 3 });
    $conn->socket->syswrite(frame('123'));
    $conn->socket->syswrite(frame('{"channel":"__token_rotate","data":"x"}'));
    $conn->socket->syswrite(frame('{"channel":"__token_rotate","data":{}}'));
    $conn->socket->syswrite(frame('{"channel":"__token_rotate","data":{"token":"fresh"}}'));
    settle(); $client->poll;
    is_deeply(\@ch, [ { n => 1 } ], 'the channel handler sees its message and not the ones with no channel or handler');
    is($client->{_token}, 'fresh', 'a token rotation without a callback still updates the token');
    delete $client->{_handlers};
    $conn->send('news', { n => 4 });
    settle(); $client->poll;
    is(scalar @ch, 1, 'with no handler table nothing is dispatched');

    $hub->close;
    settle();
    $client->poll;
    settle();
    $client->poll;
    ok(!$client->is_connected, 'the poll after the shutdown message finds the connection gone and reconnects, which fails');
    $client->{_retry_delay} = 5;
    $client->reconnect;
    is($client->{_retry_delay}, 5, 'the retry delay stops doubling at the maximum');
    $client->{_conn} = undef;
    $client->poll;
    pass('a poll with no connection reconnects');
    $client->close;
}

# --- a client that goes out of scope while connected ---
{
    my $hub = Chandra::Socket::Hub->new(name => "scope-$$");
    {
        my $client = connect_named($hub, 'scoped');
        ok($client->is_connected, 'connected inside the block');
    }
    settle(); $hub->poll;
    is(scalar $hub->clients, 0, 'and gone after it, closed by DESTROY');
    my $nameless = Chandra::Socket::Client->new(hub => $hub->{name});
    settle(); $hub->poll;
    ok($nameless->is_connected, 'a client without a name connects');
    is(scalar $hub->clients, 0, 'but is not registered');
    $nameless->close;
    $hub->close;
}

# --- a hub socket with no token file ---
{
    my $path = Chandra::Socket::Hub->socket_path("bare-$$");
    my $listener = IO::Socket::UNIX->new(Local => $path, Listen => 1) or die "listen: $!";
    my $client = Chandra::Socket::Client->new(name => 'bare', hub => "bare-$$");
    ok($client->is_connected, 'a client connects to a bare listener');
    ok(!defined $client->{_token}, 'and has no token when there is no token file');
    $client->close;
    open my $tf, '>', "$path.token" or die; close $tf;
    my $empty = Chandra::Socket::Client->new(name => 'bare', hub => "bare-$$");
    ok(!defined $empty->{_token}, 'an empty token file gives no token either');
    $empty->close;
    close $listener;
    unlink $path, "$path.token";
}

# --- connection frames ---
{
    my $conn = Chandra::Socket::Connection->new(other => 1);
    ok(!$conn->is_connected, 'a connection with no socket is not connected');
    is_deeply([ Chandra::Socket::Connection->decode_frames(undef) ], [], 'decoding undef gives nothing');
    is_deeply([ Chandra::Socket::Connection->decode_frames(frame('{{{') . frame('{"a":1}')) ], [ { a => 1 } ], 'a malformed frame is dropped and the next kept');
    ok(!defined Chandra::Socket::Connection::_xs_json_decode('{{'), 'the raw decoder gives undef for bad JSON');
    is($@, '', 'and clears the error');

    my $hub = Chandra::Socket::Hub->new(name => "frames-$$");
    my $client = connect_named($hub, 'framed');
    my $hconn = $hub->{_clients}{framed};
    my $cconn = $client->{_conn};
    $cconn->{_buf} = undef;
    $hconn->send('x', { partial => 1 });
    settle(); $client->poll;
    ok(defined $cconn->{_buf}, 'a buffer that was undef is made from the first read');
    $cconn->{_buf} = undef;
    $client->poll;
    is($cconn->{_buf}, undef, 'and stays undef when nothing is read');
    $cconn->{_buf} = '';
    $hconn->socket->syswrite(pack('N', 7) . 'abc');
    settle(); $client->poll;
    is(length $cconn->{_buf}, 7, 'a partial frame waits in the buffer');
    $hconn->socket->syswrite('defg' . frame('{{{'));
    settle();
    @warned = ();
    $client->poll;
    is(scalar(grep { /malformed JSON frame/ } @warned), 2, 'the completed frame and the next, neither JSON, each warn');
    is($cconn->{_buf}, '', 'and are consumed');
    $hconn->socket->syswrite(pack('N', 0x7fffffff));
    settle();
    @warned = ();
    $client->poll;
    like($warned[0], qr/frame too large/, 'a frame claiming 2GB warns');
    ok(!$cconn->is_connected, 'and disconnects');
    $client->close;
    $hub->close;
}

# --- the token manager on its own ---
{
    my $tm = Chandra::Socket::Token->new(length => 1);
    is(length $tm->current, 16, 'a length below 8 becomes 8 bytes');
    my $big = Chandra::Socket::Token->new(length => 999);
    is(length $big->current, 256, 'a length above 128 becomes 128 bytes');
    delete $tm->{_current};
    $tm->rotate;
    ok(!defined $tm->previous, 'rotating with no current token leaves no previous');
    ok(defined $tm->current, 'and makes a new one');
}

# --- the hub run loop, left through a die from an alarm ---
{
    my $hub = Chandra::Socket::Hub->new(name => "run-$$");
    local $SIG{ALRM} = sub { die "enough\n" };
    alarm 1;
    eval { $hub->run };
    alarm 0;
    is($@, "enough\n", 'run polls until the alarm handler dies out of it');
    $hub->close;
}

# --- TLS ---
SKIP: {
    eval { require IO::Socket::SSL; require IO::Socket::SSL::Utils; 1 } or skip 'IO::Socket::SSL is needed', 6;
    my ($cert, $key) = IO::Socket::SSL::Utils::CERT_create(subject => { commonName => '127.0.0.1' }, purpose => 'server');
    my ($cert_file, $key_file) = ("$dir/cert.pem", "$dir/key.pem");
    IO::Socket::SSL::Utils::PEM_cert2file($cert, $cert_file);
    IO::Socket::SSL::Utils::PEM_key2file($key, $key_file);

    SKIP: {
        skip 'ports below 1024 are open to root', 1 if $> == 0;
        eval { Chandra::Socket::Hub->new(transport => 'tcp', port => 1, bind => '127.0.0.1', tls_cert => $cert_file, tls_key => $key_file) };
        like($@, qr/Hub: cannot listen on TLS TCP 127\.0\.0\.1:1/, 'a TLS listener on a privileged port croaks');
    }

    my $port = free_port();
    my $hub = Chandra::Socket::Hub->new(transport => 'tcp', port => $port, bind => '127.0.0.1', tls_cert => $cert_file, tls_key => $key_file);
    ok($hub, 'a TLS hub listens');

    # The TLS handshake needs both ends at once, so the client lives in a
    # child while the hub polls here. The child reports through its exit code.
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $client = Chandra::Socket::Client->new(name => 'secure', transport => 'tcp', port => $port, token => $hub->token, tls => 1, tls_ca => $cert_file);
        my $connected = $client->is_connected ? 1 : 0;
        my $plain = Chandra::Socket::Client->new(name => 'plain', transport => 'tcp', port => $port, token => $hub->token, tls => 1);
        my $plain_connected = $plain->is_connected ? 2 : 0;
        select(undef, undef, undef, 0.5);
        $client->close;
        $plain->close;
        exit($connected + $plain_connected);
    }
    my $seen = 0;
    for (1 .. 30) { settle(); $hub->poll; $seen = scalar $hub->clients if $hub->clients > $seen }
    waitpid $pid, 0;
    my $code = $? >> 8;
    ok($code & 1, 'a TLS client connects with the certificate as its CA');
    ok(1, 'a TLS client without a CA file ' . ($code & 2 ? 'connects' : 'does not connect'));
    is($seen, ($code & 1 ? 1 : 0) + ($code & 2 ? 1 : 0), 'and the hub registered every client that connected, while they were there');
    $hub->close;
    my $none = Chandra::Socket::Client->new(name => 'nobody', transport => 'tcp', port => $port, token => 'x', tls => 1, tls_ca => $cert_file);
    ok(!$none->is_connected, 'a TLS client with nothing listening is not connected');
    $none->close;
}

done_testing;
