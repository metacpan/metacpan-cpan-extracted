#!/usr/bin/env perl
# plan_clamav_clamd phase 0 - INSTREAM against the StreamMaxLength ceiling.
#
# Streams a file in chunks rather than slurping it, and watches for a
# reply arriving DURING the write - which is the case that makes INSTREAM
# harder than FILDES, and the one that looks like a network failure if
# nobody is looking for it.
use strict;
use warnings;
use IO::Socket::UNIX;
use IO::Select;

my $SOCK  = $ENV{CLAMD_SOCK} || '/opt/homebrew/var/run/clamav/clamd.sock';
my $CHUNK = $ENV{CHUNK} || 65536;

sub esc { my $b = shift; return '<none>' unless defined $b && length $b;
          $b =~ s/\0/\\0/g; $b =~ s/\n/\\n/g; return $b }

for my $file (@ARGV) {
    open my $fh, '<:raw', $file or die "open $file: $!";
    my $size = -s $file;

    my $s = IO::Socket::UNIX->new(Peer => $SOCK, Type => SOCK_STREAM)
        or die "connect: $!";
    $s->autoflush(1);
    syswrite($s, "zINSTREAM\0");

    my $sel = IO::Select->new($s);
    my ($sent, $early, $reply, $werr) = (0, 0, '', undef);

    # SIGPIPE would kill us mid-measurement; we want to SEE the EPIPE.
    local $SIG{PIPE} = 'IGNORE';

    while (read($fh, my $buf, $CHUNK)) {
        # A reply arriving mid-write is a verdict, not a failure.
        if ($sel->can_read(0)) {
            my $n = sysread($s, my $r, 4096);
            if (defined $n && $n > 0) { $reply .= $r; $early = $sent; last }
        }
        my $w = syswrite($s, pack('N', length $buf) . $buf);
        if (!defined $w) { $werr = "$!"; last }
        $sent += length $buf;
    }
    close $fh;

    unless (defined $werr || length $reply) {
        syswrite($s, pack('N', 0));
        while ($sel->can_read(10)) {
            my $n = sysread($s, my $r, 4096);
            last if !defined $n || $n == 0;
            $reply .= $r;
        }
    }
    close $s;

    printf "  %-16s %11d bytes  sent=%-11d %s\n     reply=%s%s\n",
        (split m{/}, $file)[-1], $size, $sent,
        ($early ? "EARLY REPLY after $early bytes" : 'wrote all'),
        esc($reply),
        (defined $werr ? "   [write failed: $werr]" : '');
}
