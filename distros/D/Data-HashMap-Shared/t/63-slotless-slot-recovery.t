use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Data::HashMap::Shared::II;

# With every reader slot taken a handle runs slotless: the lock still works,
# but the handle's death is no longer recoverable.  Rescanning all 1024 slots
# on each operation costs a kill(2) per live owner, so a slotless handle backs
# off and only retries occasionally.  What the back-off risks is never retrying
# at all, leaving a handle slotless for the rest of its life while slots sit
# free, so that is what this pins.
#
# The table is filled with the parent's pid: alive, so pass 2 reclaims none of
# them, which is the only way to reach the slotless path without 1024 processes.

use constant { SLOTS => 1024, SLOT_SIZE => 16 };

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/slotless.shm";
my $out  = "$dir/child.out";

my $m = Data::HashMap::Shared::II->new($path, 1000);
$m->put(9_000_000, 7);          # outside every key the probe child writes

my $slots_off = do {
    open my $fh, '<:raw', $path or die $!;
    read $fh, my $h, 160 or die $!;
    unpack 'Q<', substr($h, 80, 8);
};

sub slot_pids {
    open my $fh, '<:raw', $path or die $!;
    seek $fh, $slots_off, 0 or die $!;
    read $fh, my $b, SLOTS * SLOT_SIZE or die $!;
    close $fh;
    return map { unpack 'L', substr($b, $_ * SLOT_SIZE, 4) } 0 .. SLOTS - 1;
}
sub poke_pid {
    my ($idx, $pid) = @_;
    open my $fh, '+<:raw', $path or die $!;
    seek $fh, $slots_off + $idx * SLOT_SIZE, 0 or die $!;
    print $fh pack 'L', $pid;
    close $fh or die $!;
}

my $ppid = $$;
# Pass 1 starts at pid % SLOTS and takes the first free slot, so on a fresh map
# this one is the parent's.  Freeing its neighbour cannot disturb it.
my $free_idx = ($ppid + 1) % SLOTS;

my $pid = fork // die "fork: $!";
if (!$pid) {
    $SIG{ALRM} = 'DEFAULT'; alarm 60;
    open my $log, '>', $out or POSIX::_exit(3);
    eval {
        poke_pid($_, $ppid) for 0 .. SLOTS - 1;

        my $c = Data::HashMap::Shared::II->new($path, 1000);
        $c->put(2, 2);
        printf $log "slotless=%d\n", (grep { $_ == $$ } slot_pids()) ? 0 : 1;

        my $bad = 0;
        for my $i (1 .. 300) {
            $c->put($i, $i * 3);
            $bad++ unless ($c->get($i) // -1) == $i * 3;
        }
        printf $log "wrong_while_slotless=%d\n", $bad;

        poke_pid($free_idx, 0);
        my $claimed_at = 0;
        for my $i (1 .. 400) {
            $c->put(1000 + $i, $i);
            $claimed_at = $i if !$claimed_at && grep { $_ == $$ } slot_pids();
        }
        printf $log "claimed_at=%d\n", $claimed_at;
        printf $log "final=%d\n", $c->get(1300) // -1;
        1;
    } or print $log "error=$@\n";
    close $log;
    POSIX::_exit(0);
}
waitpid $pid, 0;
is $? & 127, 0, 'the probe child neither hung nor crashed' or BAIL_OUT('child died');

my %r;
open my $fh, '<', $out or die "no child output: $!";
while (<$fh>) { chomp; my ($k, $v) = split /=/, $_, 2; $r{$k} = $v }
close $fh;
is $r{error}, undef, 'the probe ran to the end' or diag $r{error};

is $r{slotless}, 1, 'a handle finding every slot taken runs slotless';
is $r{wrong_while_slotless}, 0, '  ... and reads back every value it wrote';
cmp_ok $r{claimed_at}, '>', 0, 'a freed slot is picked up rather than ignored for good';
cmp_ok $r{claimed_at}, '<=', 300, '  ... within the back-off interval, not eventually';
is $r{final}, 300, '  ... and the map is intact across the transition';

is $m->get(9_000_000), 7, 'the map still serves the parent afterwards';

done_testing;
