#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';

use Atomic::Pipe;
use Cpanel::JSON::XS ();
use Time::HiRes qw(time);
use POSIX ();

# --- corpus generation ---------------------------------------------------
#
# Generate ~10MB of JSON objects, one object per "message". Each object's
# JSON encoding is bounded between ~80B and ~2000B, with a fair share under
# 500B. Deterministic: same corpus every run.

my $TARGET_BYTES = 100 * 1024 * 1024;
my $MAX_OBJ      = 10_000;
my $MIN_OBJ      = 200;

srand(0xA70A1C);  # fixed seed

my @WORDS = qw(
    alpha bravo charlie delta echo foxtrot golf hotel india juliet
    kilo lima mike november oscar papa quebec romeo sierra tango
    uniform victor whiskey xray yankee zulu prod stage dev test ci
    queue worker job task event message stream pipe buffer compress
    decompress error info warn debug trace fatal user account auth
    token session request response payload metric counter gauge
);
my @STATUSES = qw(ok pending failed retry skipped);
my @REGIONS  = qw(us-east-1 us-west-2 eu-central-1 ap-south-1 sa-east-1);

sub rand_word { $WORDS[int rand @WORDS] }
sub rand_sentence {
    my $n = 3 + int rand 12;
    join ' ', map { rand_word() } 1 .. $n;
}
sub rand_tags {
    my $n = int rand 6;
    [ map { rand_word() } 1 .. $n ];
}

my $json = Cpanel::JSON::XS->new->utf8(0)->canonical(0);

sub build_object {
    my $obj = {
        id        => int(rand(2**31)),
        ts        => 1_700_000_000 + int(rand(60_000_000)),
        user      => rand_word() . int(rand(10000)),
        status    => $STATUSES[int rand @STATUSES],
        region    => $REGIONS[int rand @REGIONS],
        tags      => rand_tags(),
        latency_ms => sprintf('%.3f', rand() * 500),
    };
    # Envelope ~150B JSON. Pick total target across [$MIN_OBJ, $MAX_OBJ];
    # subtract envelope to size payload.
    my $envelope = 150;
    my $total_target = $MIN_OBJ + int rand($MAX_OBJ - $MIN_OBJ + 1);
    my $payload_target = $total_target > $envelope ? $total_target - $envelope : 1;
    my $msg = '';
    while (length($msg) < $payload_target) {
        $msg .= rand_sentence() . ' ';
    }
    $obj->{message} = substr($msg, 0, $payload_target);
    return $obj;
}

print "Generating corpus...\n";
my $gen_start = time;
my @CORPUS;
my $total_raw = 0;
while ($total_raw < $TARGET_BYTES) {
    my $obj = build_object();
    my $enc = $json->encode($obj);

    # Trim if above MAX
    if (length($enc) > $MAX_OBJ) {
        my $excess = length($enc) - $MAX_OBJ;
        $obj->{message} = substr($obj->{message}, 0, length($obj->{message}) - $excess);
        $enc = $json->encode($obj);
    }
    push @CORPUS, $enc;
    $total_raw += length($enc);
}

my $gen_elapsed = time - $gen_start;
my $count = scalar @CORPUS;
my $min_len = $MAX_OBJ; my $max_len = 0;
my %bucket;  # 0-1k, 1-2k, ..., 9-10k
for my $e (@CORPUS) {
    my $l = length $e;
    $min_len = $l if $l < $min_len;
    $max_len = $l if $l > $max_len;
    my $b = int($l / 1000);
    $bucket{$b}++;
}

printf "  objects:        %d\n", $count;
printf "  total raw:      %.2f MB (%d bytes)\n", $total_raw / (1024*1024), $total_raw;
printf "  size range:     %d .. %d bytes\n", $min_len, $max_len;
printf "  avg size:       %.0f bytes\n", $total_raw / $count;
print  "  size buckets (kB):\n";
for my $b (sort { $a <=> $b } keys %bucket) {
    printf "    %d-%dk: %d (%.1f%%)\n", $b, $b+1, $bucket{$b}, 100*$bucket{$b}/$count;
}
printf "  generated in:   %.2fs\n\n", $gen_elapsed;

# --- benchmark scenario --------------------------------------------------
#
# Fork: child writes every JSON object as a message in mixed_data_mode.
# Parent reads via get_line_burst_or_data() until EOF. Wall-clock from just
# before fork until reader sees EOF == end-to-end IPC throughput.
#
# Compressed run: keep_compressed=1 so reader can sum on-wire (compressed)
# bytes — this is the actual buffer space cost in the pipe.

sub run_scenario {
    my (%opts) = @_;
    my $compressed = $opts{compression} ? 1 : 0;

    my @pair_args = (mixed_data_mode => 1);
    if ($compressed) {
        push @pair_args, compression => 'zstd', keep_compressed => 1;
        push @pair_args, compression_level => $opts{level} if defined $opts{level};
    }

    my ($r, $w) = Atomic::Pipe->pair(@pair_args);

    if (defined(my $sz = $opts{pipe_size})) {
        my $got = $w->resize($sz);
        $opts{actual_pipe_size} = $got;
    }

    my $start = time;
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;

    if (!$pid) {
        # writer
        $r->close;
        for my $obj (@CORPUS) {
            $w->write_message($obj);
        }
        $w->close;
        POSIX::_exit(0);
    }

    # reader
    $w->close;
    my $msgs       = 0;
    my $raw_bytes  = 0;
    my $wire_bytes = 0;
    while (1) {
        my %r = $r->get_line_burst_or_data;
        last if $r->eof && !%r;
        next unless %r;
        if (defined $r{message}) {
            $msgs++;
            $raw_bytes  += length $r{message};
            $wire_bytes += length($r{compressed} // $r{message});
        }
    }
    waitpid($pid, 0);
    my $elapsed = time - $start;
    $r->close;

    return {
        compressed => $compressed,
        msgs       => $msgs,
        raw_bytes  => $raw_bytes,
        wire_bytes => $wire_bytes,
        elapsed    => $elapsed,
    };
}

sub mb { $_[0] / (1024 * 1024) }

sub report {
    my ($label, $res) = @_;
    printf "%s\n", $label;
    printf "  messages:       %d\n", $res->{msgs};
    printf "  raw bytes:      %d (%.2f MB)\n", $res->{raw_bytes}, mb($res->{raw_bytes});
    printf "  wire bytes:     %d (%.2f MB)\n", $res->{wire_bytes}, mb($res->{wire_bytes});
    printf "  elapsed:        %.3fs\n", $res->{elapsed};
    printf "  raw throughput: %.2f MB/s\n",  mb($res->{raw_bytes})  / $res->{elapsed};
    printf "  wire throughput:%.2f MB/s\n",  mb($res->{wire_bytes}) / $res->{elapsed};
    if ($res->{compressed}) {
        my $ratio = $res->{raw_bytes} / $res->{wire_bytes};
        my $saved = $res->{raw_bytes} - $res->{wire_bytes};
        printf "  ratio:          %.2fx (raw/wire)\n", $ratio;
        printf "  pct of raw:     %.1f%% on the wire\n", 100 * $res->{wire_bytes} / $res->{raw_bytes};
        printf "  saved:          %d bytes (%.2f MB, %.1f%% reduction)\n",
            $saved, mb($saved), 100 * $saved / $res->{raw_bytes};
    }
    print "\n";
}

# Sweep pipe buffer sizes x compression modes.
my @PIPE_SIZES = (32*1024, 128*1024, 512*1024, 1024*1024);
my @MODES = (
    { name => 'plain', compression => 0 },
    { name => 'L-3',   compression => 1, level => -3 },
    { name => 'L1',    compression => 1, level => 1 },
    { name => 'L3',    compression => 1, level => 3 },
);

my @results;
for my $psize (@PIPE_SIZES) {
    for my $mode (@MODES) {
        printf "Running %-6s pipe=%dk...\n", $mode->{name}, $psize/1024;
        my $r = run_scenario(
            compression => $mode->{compression},
            (defined $mode->{level} ? (level => $mode->{level}) : ()),
            pipe_size => $psize,
        );
        $r->{mode} = $mode->{name};
        $r->{pipe_size} = $psize;
        push @results, $r;
    }
}

print "\n=== summary ===\n";
printf "%-6s %-8s %12s %12s %10s %10s %10s\n",
    'mode', 'pipe', 'raw MB/s', 'wire MB/s', 'elapsed', 'wire MB', 'ratio';
for my $r (@results) {
    my $ratio = $r->{compressed} ? sprintf('%.2fx', $r->{raw_bytes} / $r->{wire_bytes}) : '-';
    printf "%-6s %-8s %12.2f %12.2f %10.3f %10.2f %10s\n",
        $r->{mode},
        sprintf('%dk', $r->{pipe_size}/1024),
        mb($r->{raw_bytes})  / $r->{elapsed},
        mb($r->{wire_bytes}) / $r->{elapsed},
        $r->{elapsed},
        mb($r->{wire_bytes}),
        $ratio;
}
