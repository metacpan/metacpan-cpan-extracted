use strict;
use warnings;
use Test::More;
use IO::Socket::INET ();
use IO::Select ();
use ClamAV::Clamd;

# TCP, against a listener in THIS process. No fork and no UNIX socket, so
# it runs where the fake cannot - Windows - and it is the only file that
# exercises the client there.
#
# One process can play both ends because the kernel completes a TCP
# handshake out of the listen backlog: the client connects before anybody
# calls accept, and the async surface lets the test take turns after that.

sub listener {
    my $l = IO::Socket::INET->new(
        Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp',
    );
    return $l;
}

my $probe = listener();
plan skip_all => "cannot listen on 127.0.0.1: $!" unless $probe;

# --- nobody listening ---------------------------------------------------
{
    my $port = $probe->sockport;
    close $probe;

    my $c = ClamAV::Clamd->new(host => '127.0.0.1', port => $port, connect_timeout => 5);
    is $c->ping, undef, 'a refused TCP connect returns undef';
    is $c->error_code, ClamAV::Clamd::ERR_CONNECT, '  reported as a connect error';
}

# --- connected, and never answered --------------------------------------
{
    my $l = listener() or die "listen: $!";
    my $c = ClamAV::Clamd->new(host => '127.0.0.1', port => $l->sockport,
                               reply_timeout => 1);
    my $t0 = time;
    is $c->ping, undef, 'a peer that never answers returns undef';
    is $c->error_code, ClamAV::Clamd::ERR_TIMEOUT, '  reported as a timeout';
    cmp_ok time - $t0, '<', 10, '  within the configured timeout, not forever';
}

# --- a whole INSTREAM scan, both ends in turn ---------------------------
sub scan_over_tcp {
    my ($bytes, $reply, %opt) = @_;

    my $l = listener() or die "listen: $!";
    my $c = ClamAV::Clamd->new(host => '127.0.0.1', port => $l->sockport,
                               reply_timeout => 20, %opt);
    my $s = $c->start_scan($bytes);

    die 'the client never arrived' unless IO::Select->new($l)->can_read(10);
    my $peer = $l->accept or die "accept: $!";
    binmode $peer;
    $peer->blocking(0);

    my ($got, $answered, $guard) = ('', 0, 0);
    my $sel = IO::Select->new($peer);
    until ($s->is_done) {
        die 'the scan ran away' if ++$guard > 20_000;
        $s->step;
        while ($sel->can_read(0.01)) {
            my $n = sysread($peer, my $buf, 65536);
            last unless $n;
            $got .= $buf;
        }
        # Four zero bytes end the stream. Answer once they have arrived.
        if (!$answered && $got =~ /\0\0\0\0\z/) {
            syswrite($peer, "$reply\0");
            $answered = 1;
        }
    }
    close $peer;
    return ($s, $got);
}

{
    my $bytes = join '', map { chr($_ % 256) } 0 .. 199_999;
    my ($s, $got) = scan_over_tcp($bytes, 'stream: OK', chunk => 4096);

    is $s->verdict->state, 'clean', 'a scan over TCP reaches a verdict';
    is $s->verdict->transport, 'instream', '  over INSTREAM';

    # Unframe what arrived and compare it with what was sent. Every byte
    # value is in there, including \r\n and ^Z, so a text-mode or
    # truncating path cannot pass this.
    ok $got =~ s/\AzINSTREAM\0//, '  the command arrived first';
    my ($body, $ok) = ('', 1);
    while (length $got >= 4) {
        my $len = unpack 'N', substr($got, 0, 4, '');
        last if $len == 0;
        if ($len > length $got) { $ok = 0; last }
        $body .= substr($got, 0, $len, '');
    }
    ok $ok && $got eq '', '  the chunks are framed and the stream is terminated';
    is length $body, length $bytes, '  every byte arrived';
    ok $body eq $bytes, '  and they are the bytes that were sent';
}

{
    my ($s) = scan_over_tcp('payload', 'stream: Eicar-Test-Signature FOUND');
    is $s->verdict->state, 'infected', 'an infected verdict comes back over TCP';
    is $s->verdict->signature, 'Eicar-Test-Signature', '  with its signature';
}

# --- a file, which over TCP has to be streamed --------------------------
{
    require File::Temp;
    my $dir  = File::Temp->newdir();
    my $path = "$dir/sample.bin";
    my $bytes = join '', map { chr($_ % 256) } 0 .. 69_999;
    open my $fh, '>:raw', $path or die "open: $!";
    print {$fh} $bytes;
    close $fh;

    my $l = listener() or die "listen: $!";
    my $c = ClamAV::Clamd->new(host => '127.0.0.1', port => $l->sockport,
                               reply_timeout => 20);
    my $s = $c->start_scan($path, 'path');

    die 'the client never arrived' unless IO::Select->new($l)->can_read(10);
    my $peer = $l->accept or die "accept: $!";
    binmode $peer;
    $peer->blocking(0);

    my ($got, $answered, $guard) = ('', 0, 0);
    my $sel = IO::Select->new($peer);
    until ($s->is_done) {
        die 'the scan ran away' if ++$guard > 20_000;
        $s->step;
        while ($sel->can_read(0.01)) {
            my $n = sysread($peer, my $buf, 65536);
            last unless $n;
            $got .= $buf;
        }
        if (!$answered && $got =~ /\0\0\0\0\z/) {
            syswrite($peer, "stream: OK\0");
            $answered = 1;
        }
    }
    close $peer;

    is $s->verdict->state, 'clean', 'a path scanned over TCP reaches a verdict';
    $got =~ s/\AzINSTREAM\0//;
    my $body = '';
    while (length $got >= 4) {
        my $len = unpack 'N', substr($got, 0, 4, '');
        last if $len == 0 || $len > length $got;
        $body .= substr($got, 0, $len, '');
    }
    ok $body eq $bytes, '  and the file crossed the socket byte for byte';
}

done_testing;
