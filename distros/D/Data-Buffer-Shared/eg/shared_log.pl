#!/usr/bin/env perl
# Shared append-only log: atomic write index + Str record buffer
#
# Multiple writers atomically claim a slot, write a fixed-size record.
# Reader tails the log by polling the write index.
use strict;
use warnings;
use POSIX qw(_exit strftime);
use Time::HiRes qw(time sleep);

use Data::Buffer::Shared::Str;
use Data::Buffer::Shared::I64;

my $max_entries = 256;
my $record_size = 64;  # fixed-size log records

my $log = Data::Buffer::Shared::Str->new_anon($max_entries, $record_size);
my $ctl = Data::Buffer::Shared::I64->new_anon(2);
# ctl[0] = write index (next slot to write)
# ctl[1] = quit flag

my $nwriters = 3;
my $msgs_per = 20;

# writers: claim slot via atomic incr, then write record
my @pids;
for my $w (1..$nwriters) {
    my $pid = fork();
    if ($pid == 0) {
        for my $m (1..$msgs_per) {
            # atomic claim: incr returns new value, so slot = new - 1
            my $slot = $ctl->incr(0) - 1;
            my $idx = $slot % $max_entries;  # wrap around
            my $msg = sprintf("[w%d] msg %03d t=%.3f", $w, $m, time());
            $log->set($idx, $msg);
        }
        _exit(0);
    }
    push @pids, $pid;
}

# reader: tail the log
my $read_pos = 0;
my $total_expected = $nwriters * $msgs_per;
my @seen;

while ($read_pos < $total_expected) {
    my $write_pos = $ctl->get(0);
    while ($read_pos < $write_pos && $read_pos < $total_expected) {
        my $idx = $read_pos % $max_entries;
        my $record = $log->get($idx);
        push @seen, $record if $record;
        $read_pos++;
    }
    sleep 0.001 if $read_pos < $total_expected;
}

waitpid($_, 0) for @pids;

printf "shared log: %d writers x %d msgs = %d total\n",
    $nwriters, $msgs_per, $total_expected;
printf "records read: %d\n", scalar @seen;
printf "first 5 records:\n";
printf "  %s\n", $_ for @seen[0..4];
printf "last record:\n  %s\n", $seen[-1];
