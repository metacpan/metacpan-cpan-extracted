#!/usr/bin/env perl
# No-DB pipe transport bench on real Test2 event JSON (events.jsonl).
# usage: bench_pipe.pl  (env: WRITERS=1,8  SHAPES=event,frame  REPS=3  READER=fast,json)
#   shape event: each message is one event JSON line (the Test2-Harness2 case)
#   shape frame: each message is Storable freeze of 1000 event strings (~1.6MB, the ORM fork-builder case)
#   reader fast: count bytes; json: decode every event (reader is the slow side)
use strict;
use warnings;
use lib $ENV{APLIB};
use Atomic::Pipe;
use Storable qw/freeze thaw/;
use Cpanel::JSON::XS;
use Compress::Zstd ();
use Compress::Zstd::Compressor;
use Compress::Zstd::Decompressor;
use Fcntl;
use POSIX ();
use Time::HiRes qw/time/;
use FindBin;
$| = 1;

my @W      = split /,/, ($ENV{WRITERS} // '1,8');
my @SHAPES = split /,/, ($ENV{SHAPES}  // 'event,frame');
my @READER = split /,/, ($ENV{READER}  // 'fast,json');
my $REPS   = $ENV{REPS} // 3;

open my $fh, '<', "$FindBin::Bin/events.jsonl" or die $!;
my @EV = grep { length } map { chomp; $_ } <$fh>;
close $fh;
my %MSGS;
$MSGS{event} = \@EV;
for (my $i = 0; $i < @EV; $i += 1000) {
    my $e = $i + 999 > $#EV ? $#EV : $i + 999;
    push @{$MSGS{frame}}, freeze([@EV[$i .. $e]]);
}

my $J = Cpanel::JSON::XS->new;
sub consume {
    my ($shape, $mode, $msg) = @_;
    return length($msg) if $mode eq 'fast';
    if ($shape eq 'event') { $J->decode($msg); return length $msg }
    my $l = thaw($msg);
    $J->decode($_) for @$l;
    return length $msg;
}

my %T;
# Atomic::Pipe, many writers share one pipe.
$T{ap_plain} = $T{ap_zstd} = $T{apm_plain} = $T{apm_zstd} = $T{ap_large} = $T{apm_large} = sub {
    my ($name, $shape, $mode, $nw) = @_;
    my $mixed = $name =~ /^apm/;
    my @args = ($name =~ /zstd/ ? (compression => 'zstd') : (),
        $name =~ /large/ ? (compression => 'zstd', compress_large_only => 1) : (), $mixed ? (mixed_data_mode => 1) : ());
    my ($r, $w) = Atomic::Pipe->pair(@args);
    $w->resize(1 << 20);
    my $t0 = time;
    my @pids;
    for (1 .. $nw) {
        my $pid = fork // die;
        unless ($pid) { $r->close; $w->write_message($_) for @{$MSGS{$shape}}; $w->close; POSIX::_exit(0) }
        push @pids, $pid;
    }
    $w->close;
    my ($n, $b) = (0, 0);
    if ($mixed) {
        while (1) {
            my %m = $r->get_line_burst_or_data;
            last if !%m && $r->eof;
            next unless defined $m{message};
            $n++; $b += consume($shape, $mode, $m{message});
        }
    }
    else {
        while (defined(my $m = $r->read_message)) { $n++; $b += consume($shape, $mode, $m) }
    }
    waitpid($_, 0) for @pids;
    return (time - $t0, $n, $b);
};

# Plain pipes, one per writer (a non-atomic design must not share), 4-byte length prefix, optional streaming zstd.
$T{raw_lp} = $T{raw_zs} = sub {
    my ($name, $shape, $mode, $nw) = @_;
    my $zs = $name eq 'raw_zs';
    my $t0 = time;
    my (@rd, @pids);
    for (1 .. $nw) {
        pipe(my $r, my $w) or die;
        fcntl($w, Fcntl::F_SETPIPE_SZ(), 1 << 20);
        my $pid = fork // die;
        unless ($pid) {
            close $r; close $_ for @rd;
            my $c = $zs ? Compress::Zstd::Compressor->new(3) : undef;
            for my $m (@{$MSGS{$shape}}) {
                my $out = pack('N', length $m) . $m;
                $out = $c->compress($out) . $c->flush if $zs;
                syswrite_all($w, $out);
            }
            syswrite_all($w, $c->end) if $zs;
            close $w; POSIX::_exit(0);
        }
        close $w;
        push @rd, $r; push @pids, $pid;
    }
    my ($n, $b) = (0, 0);
    my %st = map { (fileno($_) => {fh => $_, buf => '', d => ($zs ? Compress::Zstd::Decompressor->new : undef)}) } @rd;
    while (%st) {
        my $rin = '';
        vec($rin, $_, 1) = 1 for keys %st;
        select(my $rout = $rin, undef, undef, undef) > 0 or next;
        for my $fd (keys %st) {
            next unless vec($rout, $fd, 1);
            my $s = $st{$fd};
            my $got = sysread($s->{fh}, my $buf, 1 << 20);
            unless ($got) { delete $st{$fd}; next }
            $s->{buf} .= $zs ? $s->{d}->decompress($buf) : $buf;
            while (length($s->{buf}) >= 4) {
                my $len = unpack('N', $s->{buf});
                last if length($s->{buf}) < 4 + $len;
                my $m = substr($s->{buf}, 4, $len);
                substr($s->{buf}, 0, 4 + $len, '');
                $n++; $b += consume($shape, $mode, $m);
            }
        }
    }
    waitpid($_, 0) for @pids;
    return (time - $t0, $n, $b);
};

sub syswrite_all {
    my ($w, $d) = @_;
    my $off = 0;
    while ($off < length $d) { my $x = syswrite($w, $d, length($d) - $off, $off) // die "$!"; $off += $x }
}

my @NAMES = split /,/, ($ENV{TRANSPORTS} // 'raw_lp,raw_zs,ap_plain,ap_zstd,apm_plain,apm_zstd');
for my $shape (@SHAPES) {
    my $tot = 0; $tot += length for @{$MSGS{$shape}};
    for my $mode (@READER) {
        for my $nw (@W) {
            printf "# shape=%s reader=%s writers=%d msgs/writer=%d MB/writer=%.1f\n", $shape, $mode, $nw, scalar @{$MSGS{$shape}}, $tot / 1e6;
            for my $name (@NAMES) {
                my $best;
                for (1 .. $REPS) {
                    my ($dt, $n, $b) = $T{$name}->($name, $shape, $mode, $nw);
                    die "$name: got $n msgs\n" unless $n == $nw * @{$MSGS{$shape}};
                    $best = $dt if !defined($best) || $dt < $best;
                }
                printf "PIPE\t%s\t%s\tw=%d\t%-10s\t%.3fs\t%7.1f MB/s\n", $shape, $mode, $nw, $name, $best, $nw * $tot / 1e6 / $best;
            }
        }
    }
}
