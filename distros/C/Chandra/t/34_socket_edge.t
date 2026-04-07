#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $is_win32 = $^O eq 'MSWin32';

unless ($is_win32) {
    require IO::Socket::UNIX;
}

plan skip_all => 'Unix sockets not available' unless eval { IO::Socket::UNIX->new; 1 } || 1;

use_ok('Chandra::Socket::Connection');
use_ok('Chandra::Socket::Hub');
use_ok('Chandra::Socket::Client');

# === Connection set_name ===
SKIP: {
    skip 'AF_UNIX socketpair not available on Windows', 2 if $is_win32;
    use Socket;
    socketpair(my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $s1->blocking(0);
    $s2->blocking(0);

    my $conn = Chandra::Socket::Connection->new(socket => $s1, name => 'original');
    is($conn->name, 'original', 'initial name');
    $conn->set_name('renamed');
    is($conn->name, 'renamed', 'name after set_name');

    $conn->close;
    close $s2;
}

# === Connection without socket is not connected ===
{
    my $conn = Chandra::Socket::Connection->new(name => 'no-socket');
    ok(!$conn->is_connected, 'no socket means not connected');
    is($conn->name, 'no-socket', 'name set without socket');
}

# === Connection send when disconnected returns 0 ===
{
    my $conn = Chandra::Socket::Connection->new(name => 'disconnected');
    my $result = $conn->send('test', { data => 1 });
    is($result, 0, 'send returns 0 when disconnected');
}

# === Connection recv when disconnected returns empty ===
{
    my $conn = Chandra::Socket::Connection->new(name => 'disconnected');
    my @msgs = $conn->recv;
    is(scalar @msgs, 0, 'recv returns empty when disconnected');
}

# === Connection close is idempotent ===
SKIP: {
    skip 'AF_UNIX socketpair not available on Windows', 2 if $is_win32;
    use Socket;
    socketpair(my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $s1->blocking(0);

    my $conn = Chandra::Socket::Connection->new(socket => $s1, name => 'close-test');
    $conn->close;
    ok(!$conn->is_connected, 'disconnected after close');
    eval { $conn->close };
    is($@, '', 'double close is safe');

    close $s2;
}

# === Connection reply without _id returns 0 ===
SKIP: {
    skip 'AF_UNIX socketpair not available on Windows', 1 if $is_win32;
    use Socket;
    socketpair(my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $s1->blocking(0);

    my $conn = Chandra::Socket::Connection->new(socket => $s1, name => 'reply-test');
    my $result = $conn->reply({ channel => 'test' }, { response => 1 });
    is($result, 0, 'reply returns 0 without _id in original message');

    $conn->close;
    close $s2;
}

# === Connection reply with _id works ===
SKIP: {
    skip 'AF_UNIX socketpair not available on Windows', 4 if $is_win32;
    use Socket;
    socketpair(my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $s1->blocking(0);
    $s2->blocking(0);

    my $conn1 = Chandra::Socket::Connection->new(socket => $s1, name => 'reply-sender');
    my $conn2 = Chandra::Socket::Connection->new(socket => $s2, name => 'reply-receiver');

    my $result = $conn1->reply({ channel => 'query', _id => 42 }, { answer => 'yes' });
    ok($result, 'reply with _id succeeds');

    select(undef, undef, undef, 0.05);
    my @msgs = $conn2->recv;
    is(scalar @msgs, 1, 'reply received');
    is($msgs[0]->{_reply_to}, 42, 'reply has correct _reply_to');
    is($msgs[0]->{data}{answer}, 'yes', 'reply data correct');

    $conn1->close;
    $conn2->close;
}

# === Connection reply with undef original returns 0 ===
SKIP: {
    skip 'AF_UNIX socketpair not available on Windows', 1 if $is_win32;
    use Socket;
    socketpair(my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $s1->blocking(0);

    my $conn = Chandra::Socket::Connection->new(socket => $s1, name => 'reply-nil');
    my $result = $conn->reply(undef, { data => 1 });
    is($result, 0, 'reply with undef original returns 0');

    $conn->close;
    close $s2;
}

# === Connection send with extra fields ===
SKIP: {
    skip 'AF_UNIX socketpair not available on Windows', 2 if $is_win32;
    use Socket;
    socketpair(my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $s1->blocking(0);
    $s2->blocking(0);

    my $conn1 = Chandra::Socket::Connection->new(socket => $s1, name => 'extra');
    my $conn2 = Chandra::Socket::Connection->new(socket => $s2, name => 'extra-recv');

    $conn1->send('test', { val => 1 }, { _id => 99, custom => 'field' });
    select(undef, undef, undef, 0.05);
    my @msgs = $conn2->recv;
    is($msgs[0]->{_id}, 99, 'extra _id field preserved');
    is($msgs[0]->{custom}, 'field', 'custom extra field preserved');

    $conn1->close;
    $conn2->close;
}

# === encode_frame / decode_frames with empty data ===
{
    my $frame = Chandra::Socket::Connection->encode_frame({ channel => 'empty', data => {} });
    my @decoded = Chandra::Socket::Connection->decode_frames($frame);
    is(scalar @decoded, 1, 'empty data decoded');
    is_deeply($decoded[0]->{data}, {}, 'empty data preserved');
}

# === encode_frame / decode_frames with unicode ===
{
    my $frame = Chandra::Socket::Connection->encode_frame({ channel => 'unicode', data => { text => "日本語" } });
    my @decoded = Chandra::Socket::Connection->decode_frames($frame);
    is($decoded[0]->{data}{text}, "日本語", 'unicode preserved through encode/decode');
}

# === decode_frames with empty buffer ===
{
    my @decoded = Chandra::Socket::Connection->decode_frames('');
    is(scalar @decoded, 0, 'empty buffer returns no messages');
}

# === decode_frames with incomplete length header ===
{
    my @decoded = Chandra::Socket::Connection->decode_frames("\x00\x00");
    is(scalar @decoded, 0, 'incomplete header returns no messages');
}

# === Hub send_to nonexistent client returns 0 ===
{
    my $name = "test-send-nonexist-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $result = $hub->send_to('ghost', 'test', { data => 1 });
    is($result, 0, 'send_to nonexistent client returns 0');
    $hub->close;
}

# === Hub on() returns self for chaining ===
{
    my $name = "test-on-chain-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $ret = $hub->on('test', sub { });
    is($ret, $hub, 'on() returns self');
    $hub->close;
}

# === Hub on_connect returns self ===
{
    my $name = "test-onconn-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $ret = $hub->on_connect(sub { });
    is($ret, $hub, 'on_connect returns self');
    $hub->close;
}

# === Hub on_disconnect returns self ===
{
    my $name = "test-ondisc-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $ret = $hub->on_disconnect(sub { });
    is($ret, $hub, 'on_disconnect returns self');
    $hub->close;
}

# === Hub broadcast returns self ===
{
    my $name = "test-bc-self-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $ret = $hub->broadcast('test', {});
    is($ret, $hub, 'broadcast returns self');
    $hub->close;
}

# === Hub poll returns self ===
{
    my $name = "test-poll-self-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $ret = $hub->poll;
    is($ret, $hub, 'poll returns self');
    $hub->close;
}

# === Hub clients empty initially ===
{
    my $name = "test-clients-empty-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my @clients = $hub->clients;
    is(scalar @clients, 0, 'no clients initially');
    $hub->close;
}

# === Hub socket_path class method ===
SKIP: {
    skip 'socket_path returns Unix path on non-Windows only', 1 if $is_win32;
    my $path = Chandra::Socket::Hub->socket_path('myapp');
    like($path, qr/chandra-myapp\.sock$/, 'socket_path returns correct path');
}

# === Client on() returns self ===
{
    my $name = "test-client-on-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $client = Chandra::Socket::Client->new(name => 'c1', hub => $name);
    my $ret = $client->on('msg', sub { });
    is($ret, $client, 'client on() returns self');
    $client->close;
    $hub->close;
}

# === Client poll returns self ===
{
    my $name = "test-client-poll-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $client = Chandra::Socket::Client->new(name => 'c2', hub => $name);
    my $ret = $client->poll;
    is($ret, $client, 'client poll() returns self');
    $client->close;
    $hub->close;
}

# === Client send when disconnected returns 0 ===
{
    my $client = Chandra::Socket::Client->new(name => 'noconn', hub => 'nonexistent-hub');
    ok(!$client->is_connected, 'client not connected to nonexistent hub');
    my $result = $client->send('test', { data => 1 });
    is($result, 0, 'send returns 0 when not connected');
    $client->close;
}

# === Client request when disconnected returns 0 ===
{
    my $client = Chandra::Socket::Client->new(name => 'noconn2', hub => 'nonexistent-hub2');
    my $result = $client->request('test', {}, sub { });
    is($result, 0, 'request returns 0 when not connected');
    $client->close;
}

# === Client reconnect returns self ===
{
    my $client = Chandra::Socket::Client->new(name => 'reconn', hub => 'nonexistent-hub3');
    my $ret = $client->reconnect;
    is($ret, $client, 'reconnect returns self');
    $client->close;
}

# === Client close is idempotent ===
{
    my $name = "test-client-close-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);
    my $client = Chandra::Socket::Client->new(name => 'closeme', hub => $name);
    $client->close;
    eval { $client->close };
    is($@, '', 'double close is safe');
    $hub->close;
}

# === Hub duplicate client name replaces old ===
{
    my $name = "test-dup-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);

    my $c1 = Chandra::Socket::Client->new(name => 'same-name', hub => $name);
    select(undef, undef, undef, 0.05);
    $hub->poll;
    select(undef, undef, undef, 0.05);
    $hub->poll;
    is(scalar $hub->clients, 1, 'one client');

    my $c2 = Chandra::Socket::Client->new(name => 'same-name', hub => $name);
    select(undef, undef, undef, 0.05);
    $hub->poll;
    select(undef, undef, undef, 0.05);
    $hub->poll;
    is(scalar $hub->clients, 1, 'still one client after duplicate name');

    $c1->close;
    $c2->close;
    $hub->close;
}

# === Hub authentication rejects bad token ===
SKIP: {
    skip 'Requires IO::Socket::UNIX for direct socket connection', 3 if $is_win32;
    my $name = "test-auth-$$";
    my $hub = Chandra::Socket::Hub->new(name => $name);

    # Manually connect and send bad handshake
    require IO::Socket::UNIX;
    my $dir = $ENV{XDG_RUNTIME_DIR} || $ENV{TMPDIR} || '/tmp';
    my $path = "$dir/chandra-$name.sock";
    my $sock = IO::Socket::UNIX->new(
        Peer => $path,
        Type => IO::Socket::UNIX::SOCK_STREAM(),
    );
    ok($sock, 'connected to hub socket');
    $sock->blocking(0);

    # Send handshake with wrong token
    my $conn = Chandra::Socket::Connection->new(socket => $sock, name => 'bad-client');
    $conn->send('__handshake', { name => 'bad-client', token => 'wrong_token' });

    select(undef, undef, undef, 0.05);
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $hub->poll;
        select(undef, undef, undef, 0.05);
        $hub->poll;
    }

    ok(grep({ /rejected/ } @warnings), 'bad token produces rejection warning');
    is(scalar $hub->clients, 0, 'no clients after bad auth');

    $conn->close;
    $hub->close;
}

done_testing;
