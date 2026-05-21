#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::SS;

# memfd-backed map: zero filesystem presence, shareable via the file
# descriptor across processes (fork+exec, SCM_RIGHTS). Useful for
# ephemeral shared caches that should never hit disk.

my $map = Data::HashMap::Shared::SS->new_memfd("session-cache", 10_000, 0, 60);
my $fd  = $map->memfd;
print "memfd created on fd=$fd; nothing on disk\n";

# Producer writes
$map->put("user:42", "alice");
$map->put_ttl("session:abc", "valid", 30);

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child reopens via the inherited fd — no path string needed.
    my $shared = Data::HashMap::Shared::SS->new_from_fd($fd);
    print "child sees user:42 = ", $shared->get("user:42"), "\n";
    my ($val, $ttl) = $shared->get_with_ttl("session:abc");
    print "child sees session:abc = $val (ttl=$ttl)\n";
    $shared->put("user:99", "charlie");  # mutate; parent will see this
    exit;
}
waitpid($pid, 0);
print "parent sees user:99 = ", $map->get("user:99"), "\n";
