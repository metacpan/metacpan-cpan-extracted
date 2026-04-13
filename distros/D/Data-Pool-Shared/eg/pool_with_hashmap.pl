#!/usr/bin/env perl
# Pool + HashMap: Pool stores records, HashMap indexes them by key
#
# Pattern: fixed-size record pool with O(1) lookup by name.
# Pool provides alloc/free semantics + contiguous typed storage.
# HashMap provides key→slot_id mapping for named access.
#
# Use case: shared process table, connection registry, named resource pool
#
# Requires: Data::HashMap::Shared (sibling)

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use lib "$FindBin::Bin/../../Data-HashMap-Shared/blib/lib",
        "$FindBin::Bin/../../Data-HashMap-Shared/blib/arch";

use POSIX qw(_exit);
use File::Temp qw(tmpnam);

$| = 1;
eval { require Data::Pool::Shared;    1 } or die "Data::Pool::Shared required\n";
eval { require Data::HashMap::Shared; 1 } or die "Data::HashMap::Shared required (sibling module)\n";

my $idx_path = tmpnam() . '.shm';
END { unlink $idx_path if $idx_path && -f $idx_path }

# Pool: stores connection records (Str, 256 bytes each)
my $pool = Data::Pool::Shared::Str->new(undef, 64, 256);

# HashMap: maps connection name (string) → pool slot index (int)
my $index = Data::HashMap::Shared::SI->new($idx_path, 128);

printf "registry: pool=%d slots, index=%d entries\n",
    $pool->capacity, $index->capacity;

# --- Register connections ---
sub register {
    my ($name, $info) = @_;
    my $slot = $pool->alloc;
    return unless defined $slot;
    $pool->set($slot, $info);
    $index->put($name, $slot);
    return $slot;
}

sub lookup {
    my ($name) = @_;
    my $slot = $index->get($name);
    return unless defined $slot && $slot >= 0;
    return $pool->get($slot);
}

sub unregister {
    my ($name) = @_;
    my $slot = $index->get($name);
    return unless defined $slot && $slot >= 0;
    $pool->free($slot);
    $index->remove($name);
}

# Parent registers some connections
register("db-primary",  "host=db1.local port=5432 dbname=app user=app");
register("db-replica",  "host=db2.local port=5432 dbname=app user=readonly");
register("cache-redis", "host=redis.local port=6379 db=0");
register("mq-rabbit",   "amqp://mq.local:5672/prod");

printf "registered %d connections\n", $pool->used;

# Child process looks up by name
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    my $db = lookup("db-primary");
    printf "child: db-primary = %s\n", $db // "(not found)";

    my $cache = lookup("cache-redis");
    printf "child: cache-redis = %s\n", $cache // "(not found)";

    my $missing = lookup("nonexistent");
    printf "child: nonexistent = %s\n", $missing // "(not found)";

    # child can also register new connections
    register("worker-$$", "pid=$$ started=" . time);
    printf "child: registered worker-$$\n";

    _exit(0);
}
waitpid($pid, 0);

# Parent sees child's registration
printf "\nall connections after child:\n";
$pool->each_allocated(sub {
    printf "  slot[%d] owner=%d: %s\n",
        $_[0], $pool->owner($_[0]), $pool->get($_[0]);
});

# Cleanup
unregister("db-primary");
unregister("db-replica");
unregister("cache-redis");
unregister("mq-rabbit");
# child's registration is stale (child exited) — recover it
my $recovered = $pool->recover_stale;
printf "\nrecovered %d stale slots, pool used=%d\n", $recovered, $pool->used;
