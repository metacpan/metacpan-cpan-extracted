use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);

use Data::HashMap::Shared::SI;

# A writer killed between publishing states[insert_pos] and bumping hdr->size
# leaves the counter behind the true live count, and resize() bounds its save
# loop with hdr->size, so the entries past it are dropped by the following
# memset.  Stale-lock recovery must therefore recount from states[] even with
# LRU disabled, not only inside the LRU rebuild.

use constant {
    OFF_WLOCK  => 128,          # ShmHeader.wlock
    OFF_SIZE   => 136,          # ShmHeader.size
    WRITER_BIT => 0x80000000,
};

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/counters.hm";

my @keys = map { "crash-window-key-longer-than-inline-$_" } 1 .. 7;

# LRU disabled (max_size 0) -- the configuration that never reached the recount.
{
    my $m = Data::HashMap::Shared::SI->new($p, 1024);
    $m->put($_, 100) for @keys;
    is($m->size, scalar @keys, 'seeded map counts every entry');
}

# A pid that is certainly dead: fork, exit, reap.
my $dead = fork // die "fork: $!";
_exit(0) unless $dead;
waitpid $dead, 0;

# Simulate the crash: states[] still has all 7 live, but size is one behind,
# and the write lock is still held by the (now dead) writer.
{
    open my $fh, '+<', $p or die "open $p: $!";
    binmode $fh;
    seek $fh, OFF_SIZE, 0  or die $!; print $fh pack('L', scalar(@keys) - 1);
    seek $fh, OFF_WLOCK, 0 or die $!; print $fh pack('L', WRITER_BIT | $dead);
    close $fh or die $!;
}

my $m = Data::HashMap::Shared::SI->new($p, 1024);
$m->put('trigger-recovery-key-longer-than-inline', 1);   # takes the write lock

is($m->size, scalar(@keys) + 1, 'stale-lock recovery recounted hdr->size');

# Force a resize: pre-fix the truncated save loop drops the tail of the table.
$m->put("filler-key-longer-than-inline-$_", 200) for 1 .. 24;

my @lost = grep { !$m->exists($_) } @keys;
is(scalar @lost, 0, 'no live entry silently dropped by resize')
    or diag "lost: @lost";

done_testing;
