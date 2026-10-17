#!/usr/bin/perl
# Spec-style HTTP+SSE mock (protocol 2024-11-05) used by the test-suite:
# a chunked, long-lived event stream; POSTs are answered with 202 and the
# JSON-RPC response is delivered as a "message" event on the stream.
use strict;
use warnings;
use IO::Select;
use IO::Socket::INET;
use JSON::MaybeXS;
use Scalar::Util qw(refaddr);
use Time::HiRes qw(sleep);

my $port = shift or die "usage: $0 PORT\n";
$SIG{TERM} = sub { exit 0 };
$SIG{PIPE} = 'IGNORE';

my $lsn = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1',
                                LocalPort => $port, ReuseAddr => 1)
    or die "listen: $!";
my $sel = IO::Select->new($lsn);
my $j   = JSON::MaybeXS->new(utf8 => 1);
my (%buf, $stream);

sub chunk { my ($s, $d) = @_; print $s sprintf("%x\r\n%s\r\n", length $d, $d); $s->flush }

sub send_event {
    my ($ev, $data) = @_;
    return unless $stream;
    my $t = "event: $ev\ndata: $data\n\n";
    my $h = int(length($t) / 2);          # deliver in two pieces on purpose
    chunk($stream, substr($t, 0, $h));
    sleep 0.05;
    chunk($stream, substr($t, $h));
}

sub drop { my $fh = shift; $sel->remove($fh); delete $buf{refaddr $fh};
           undef $stream if $stream && refaddr($stream) == refaddr($fh); close $fh }

sub handle_msg {
    my $m = shift;
    return unless defined $m->{id};
    my $r = { jsonrpc => '2.0', id => $m->{id} };
    my $method = $m->{method} // '';
    if ($method eq 'initialize') {
        $r->{result} = { protocolVersion => '2024-11-05', capabilities => { tools => {} },
                         serverInfo => { name => 'mock-sse', version => '1' } };
    }
    elsif ($method eq 'tools/list') {
        $r->{result} = { tools => [ { name => 'add_numbers', description => 'Adds two numbers',
            inputSchema => { type => 'object', required => ['a', 'b'],
                properties => { a => { type => 'number' }, b => { type => 'number' } } } } ] };
    }
    elsif ($method eq 'tools/call') {
        my $a = $m->{params}{arguments} || {};
        $r->{result} = { content => [ { type => 'text', text => 'sum=' . ($a->{a} + $a->{b}) } ] };
    }
    else { $r->{error} = { code => -32601, message => 'Method not found' } }
    send_event('message', $j->encode($r));
}

sub handle {
    my $fh = shift;
    my $b  = \$buf{refaddr $fh};
    return unless $$b =~ /\r\n\r\n/;
    my ($head) = $$b =~ /\A(.*?)\r\n\r\n/s;

    if ($head =~ m{^GET /sse}) {
        print $fh "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\n"
                . "Cache-Control: no-cache\r\nTransfer-Encoding: chunked\r\n\r\n";
        $fh->flush;
        ($stream, $$b) = ($fh, '');
        send_event('endpoint', '/messages?session=abc');
    }
    elsif ($head =~ m{^POST /messages}) {
        my ($len) = $head =~ /content-length:\s*(\d+)/i;
        my $hl    = length($head) + 4;
        return if length($$b) < $hl + ($len // 0);
        my $body = substr($$b, $hl, $len);
        print $fh "HTTP/1.1 202 Accepted\r\nContent-Length: 8\r\nConnection: close\r\n\r\nAccepted";
        $fh->flush;
        drop($fh);
        handle_msg($j->decode($body));
    }
    else {
        print $fh "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        drop($fh);
    }
}

while (1) {
    for my $fh ($sel->can_read(1)) {
        if ($fh == $lsn) {
            my $c = $lsn->accept or next;
            $c->autoflush(1);
            $sel->add($c);
            $buf{refaddr $c} = '';
            next;
        }
        my $n = sysread($fh, my $d, 65536);
        if (!$n) { drop($fh); next }
        $buf{refaddr $fh} .= $d;
        handle($fh);
    }
}
