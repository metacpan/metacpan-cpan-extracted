#!/usr/bin/env perl
# plan_clamav_clamd phase 0 - capture the clamd wire grammar as raw bytes.
#
# Core modules only. This is a measurement tool, not shipped code: it
# exists so the protocol in the plan comes off a socket rather than out
# of a document.
use strict;
use warnings;
use IO::Socket::UNIX;
use IO::Socket::INET;
use IO::Select;

my $SOCK = $ENV{CLAMD_SOCK} || '/opt/homebrew/var/run/clamav/clamd.sock';
my $HOST = $ENV{CLAMD_HOST} || '127.0.0.1';
my $PORT = $ENV{CLAMD_PORT} || 3310;

my $EICAR = 'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*';

sub conn {
    my ($how) = @_;
    my $s = $how eq 'tcp'
        ? IO::Socket::INET->new(PeerHost => $HOST, PeerPort => $PORT, Proto => 'tcp')
        : IO::Socket::UNIX->new(Peer => $SOCK, Type => SOCK_STREAM);
    die "connect ($how): $!" unless $s;
    $s->autoflush(1);
    return $s;
}

# Show bytes exactly: printable as-is, everything else escaped.
sub esc {
    my ($b) = @_;
    return '<no reply>' unless defined $b && length $b;
    my $o = '';
    for my $c (split //, $b) {
        my $n = ord $c;
        $o .= $n == 0    ? '\\0'
            : $n == 10   ? '\\n'
            : $n == 13   ? '\\r'
            : ($n >= 32 && $n < 127) ? $c
            : sprintf('\\x%02x', $n);
    }
    return $o;
}

# Read until the peer closes or goes quiet. Records whether EOF was seen,
# because "reply then close" and "reply then wait" are different protocols
# and the client has to tell them apart.
sub slurp {
    my ($s, $timeout) = @_;
    $timeout ||= 5;
    my $sel = IO::Select->new($s);
    my ($buf, $eof) = ('', 0);
    while (1) {
        my @r = $sel->can_read($timeout) or last;
        my $n = sysread($s, my $chunk, 65536);
        if (!defined $n) { last }
        if ($n == 0)     { $eof = 1; last }
        $buf .= $chunk;
    }
    return ($buf, $eof);
}

sub cmd {
    my ($label, $bytes, %opt) = @_;
    my $s = conn($opt{how} || 'unix');
    syswrite($s, $bytes);
    my ($reply, $eof) = slurp($s, $opt{timeout});
    close $s;
    printf "%-34s sent=%-16s reply=%s%s\n",
        $label, esc($bytes), esc($reply), ($eof ? '  [EOF]' : '  [open]');
    return $reply;
}

print "=" x 78, "\n";
print "1. COMMAND FRAMING - which prefixes does 1.5.4 accept?\n";
print "=" x 78, "\n";
cmd('bare PING',        "PING");
cmd('bare PING + \\n',   "PING\n");
cmd('n-prefixed',       "nPING\n");
cmd('z-prefixed',       "zPING\0");
cmd('z-prefixed, no NUL', "zPING");          # framing error: what happens?
cmd('n-prefixed, no \\n', "nPING");

print "\n", "=" x 78, "\n";
print "2. TRIVIAL COMMANDS (z-framing)\n";
print "=" x 78, "\n";
cmd('zVERSION',  "zVERSION\0");
cmd('zSTATS',    "zSTATS\0");

print "\n", "=" x 78, "\n";
print "3. ERROR GRAMMAR\n";
print "=" x 78, "\n";
cmd('unknown command',  "zNOSUCHCOMMAND\0");
cmd('zSCAN missing path', "zSCAN /nonexistent/nope\0");
cmd('zFILDES over TCP',  "zFILDES\0", how => 'tcp');
cmd('zFILDES, no fd sent', "zFILDES\0");

print "\n", "=" x 78, "\n";
print "4. INSTREAM - chunk framing\n";
print "=" x 78, "\n";

sub instream {
    my ($label, $payload, %opt) = @_;
    my $s = conn($opt{how} || 'unix');
    syswrite($s, "zINSTREAM\0");
    my $csize = $opt{chunk} || length($payload) || 1;
    my $off = 0;
    my $wrote = 0;
    my $err;
    while ($off < length $payload) {
        my $piece = substr($payload, $off, $csize);
        my $n = syswrite($s, pack('N', length $piece) . $piece);
        if (!defined $n) { $err = "$!"; last }
        $wrote += length $piece;
        $off += length $piece;
    }
    syswrite($s, pack('N', 0)) unless $err;
    my ($reply, $eof) = slurp($s, $opt{timeout});
    close $s;
    printf "%-34s bytes=%-11d reply=%s%s%s\n",
        $label, $wrote, esc($reply), ($eof ? '  [EOF]' : '  [open]'),
        ($err ? "  [write failed: $err]" : '');
    return $reply;
}

instream('clean, one chunk',   'hello world');
instream('EICAR, one chunk',   $EICAR);
instream('EICAR, 8-byte chunks', $EICAR, chunk => 8);
instream('empty stream',       '');

print "\n", "=" x 78, "\n";
print "5. IDSESSION - reply tagging\n";
print "=" x 78, "\n";
{
    my $s = conn('unix');
    syswrite($s, "zIDSESSION\0");
    syswrite($s, "zPING\0");
    syswrite($s, "zVERSION\0");
    syswrite($s, "zNOSUCHCOMMAND\0");   # does one bad command kill the session?
    syswrite($s, "zPING\0");
    syswrite($s, "zEND\0");
    my ($reply, $eof) = slurp($s);
    print "session replies:\n  ", esc($reply), ($eof ? "\n  [EOF]" : "\n  [open]"), "\n";
    close $s;
}

print "\n", "=" x 78, "\n";
print "6. TCP transport sanity\n";
print "=" x 78, "\n";
cmd('zPING over TCP', "zPING\0", how => 'tcp');
instream('EICAR over TCP', $EICAR, how => 'tcp');
