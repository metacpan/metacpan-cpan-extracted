#!/usr/bin/env perl
# Async insert pipeline using EV's event loop with HTTP::Tiny-style sockets.
# This pairs ClickHouse::Encoder (sync, fast XS) with non-blocking I/O so a
# single process can keep many inserts in flight without blocking on each
# one's network round-trip.
#
# A real production setup would lean on EV::ClickHouse for the wire protocol;
# this example uses raw sockets via AnyEvent::HTTP-style ideas to keep deps
# minimal. Replace the writer with EV::ClickHouse->insert / ->query if you
# already depend on it.
#
#   perl eg/insert_async_ev.pl

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use EV;
use IO::Socket::INET;
use ClickHouse::Encoder;

my $host = $ENV{CH_HOST} // '127.0.0.1';
my $port = $ENV{CH_HTTP_PORT} // 8123;

# Encoder is plain-sync, but we feed it batches that fire whenever a timer
# elapses, simulating "every 100ms, flush whatever rolled in".
my $enc = ClickHouse::Encoder->new(columns => [
    ['id',    'UInt64'],
    ['user',  'String'],
    ['stamp', 'DateTime'],
]);

# Non-blocking HTTP POST: open socket, write request, read response in chunks.
sub http_post_async {
    my ($url, $body, $cb) = @_;
    my ($scheme, $h, $p, $path) = $url =~ m{^(https?)://([^:/]+)(?::(\d+))?(/.*)$};
    $p //= 80;
    my $sock = IO::Socket::INET->new(
        PeerAddr => $h, PeerPort => $p, Proto => 'tcp', Blocking => 0,
    );
    return $cb->(undef, "connect: $!") unless $sock;
    my $req = "POST $path HTTP/1.1\r\n"
            . "Host: $h\r\n"
            . "Content-Length: " . length($body) . "\r\n"
            . "Connection: close\r\n\r\n" . $body;
    my $sent = 0; my $resp = '';
    my ($w, $r);
    $w = EV::io($sock, EV::WRITE, sub {
        my $n = syswrite($sock, $req, length($req) - $sent, $sent);
        if (!defined $n) { return if $!{EAGAIN}; $w->stop; $cb->(undef,"write: $!"); return }
        $sent += $n;
        if ($sent >= length $req) {
            $w->stop;
            $r = EV::io($sock, EV::READ, sub {
                my $buf;
                my $n2 = sysread($sock, $buf, 8192);
                if (!defined $n2) { return if $!{EAGAIN}; $r->stop; $cb->(undef,"read: $!"); return }
                if ($n2 == 0) { $r->stop; close $sock; $cb->($resp, undef); return }
                $resp .= $buf;
            });
        }
    });
}

# Build a streamer that fires HTTP POSTs in the background, never blocking.
my $url = "http://$host:$port/?query=" .
          "insert%20into%20demo_async%20format%20Native";
my $in_flight = 0;
my $writer = sub {
    my $body = shift;
    $in_flight++;
    http_post_async($url, $body, sub {
        my ($resp, $err) = @_;
        $in_flight--;
        warn "insert failed: $err\n" if $err;
        warn "insert bad status: $resp\n"
            if $resp && $resp !~ m{\AHTTP/1\.\d 200 };
        EV::break if $in_flight == 0 && $main::done_pushing;
    });
};

my $st = $enc->streamer($writer, batch_size => 1_000);

# Setup a one-shot HTTP request to create the table synchronously first.
{
    my $sock = IO::Socket::INET->new(PeerAddr=>$host, PeerPort=>$port,
                                      Proto=>'tcp');
    my $body = 'create table if not exists demo_async '
             . '(id UInt64, user String, stamp DateTime) engine = Memory';
    print $sock "POST / HTTP/1.1\r\nHost: $host\r\n"
              . "Content-Length: " . length($body) . "\r\n"
              . "Connection: close\r\n\r\n$body";
    local $/;
    my $r = <$sock>;
    die "create table failed: $r\n" unless $r =~ m{\AHTTP/1\.\d 200 };
}

# Push 5000 rows; the streamer flushes every 1000 -> 5 concurrent requests.
my $now = time();
for my $i (1 .. 5_000) {
    $st->push_row([$i, "user_$i", $now - $i]);
}
$st->finish;
$main::done_pushing = 1;

EV::run if $in_flight > 0;
print "Done. All POSTs returned.\n";
