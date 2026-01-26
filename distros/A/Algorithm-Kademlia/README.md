# NAME

Algorithm::Kademlia - Pure Perl implementation of the Kademlia DHT algorithm

# SYNOPSIS

```perl
use Algorithm::Kademlia qw[xor_distance xor_bucket_index];

my $local_id = pack( 'H*', '00' x 20 ); # 160-bit ID
my $rt = Algorithm::Kademlia::RoutingTable->new( local_id_bin => $local_id );

# Add a peer (handles Least-Recently-Seen eviction policy)
my $stale = $rt->add_peer( $peer_id, { addr => '127.0.0.1:4001' } );
if ($stale) {
    # Bucket is full. The protocol requires you to ping the $stale node.
    # If the ping fails:
    #   $rt->evict_peer($stale->{id});
    #   $rt->add_peer($peer_id, ...);
    # If the ping succeeds:
    #   The new $peer_id is discarded (as $stale was moved to the tail).
}

# Storage for the DHT
my $storage = Algorithm::Kademlia::Storage->new( ttl => 3600 );
$storage->put($key_bin, $value_bin);

# State management for iterative lookups
my $search = Algorithm::Kademlia::Search->new(
    target_id_bin => $target_key,
    alpha         => 3
);
$search->add_candidates($rt->find_closest($target_key));

while (!$search->is_finished) {
    my @to_query = $search->next_to_query();
    for my $node (@to_query) {
        # ... Send FIND_NODE RPC to $node ...
        # If response: $search->mark_responded($node->{id}, @found_peers);
        # If failure:  $search->mark_failed($node->{id});
    }
}
my @results = $search->best_results();
```

# DESCRIPTION

`Algorithm::Kademlia` provides the mathematical and structural foundations for a Kademlia Distributed Hash Table
(DHT). It is designed to be protocol-agnostic, meaning it only handles the XOR-metric distance calculations, the
k-bucket routing table logic, and the search state management.

This module is suitable for building BitTorrent-compatible DHTs, libp2p Kademlia implementations, or custom
peer-to-peer storage systems.

# FUNCTIONS

These are bitwise logic utilities for the Kademlia XOR metrics.

## `xor_distance( $id1, $id2 )`

Returns the bitwise XOR of two binary strings.

```perl
my $id1  = pack('H*', '00' x 20);
my $id2  = pack('H*', 'ff' x 20);
my $dist = xor_distance($id1, $id2);
say unpack('H*', $dist); # ffffffffffffffffffffffffffffffffffffffff
```

## `xor_bucket_index( $id1, $id2 )`

Calculates the index of the k-bucket that `$id2` would fall into relative to `$id1`. Returns `undef` if the IDs are
identical.

The index corresponds to the bit position of the most significant bit that differs between the two IDs. For 160-bit
IDs, the result is between 0 and 159.

```perl
my $local = pack('H*', '00' x 20);
my $peer  = pack('H*', '80' . ('00' x 19)); # 160th bit differs
my $idx   = xor_bucket_index($local, $peer);
say $idx; # 159
```

# Algorithm::Kademlia::RoutingTable

This class implements the 160 k-bucket structure (or appropriate size for the ID length provided). Peers are bucketed
by their XOR distance from the local node ID.

## `new( local_id_bin => ..., [ k => 20 ] )`

Constructor. `local_id_bin` is the binary string of the local node's ID.

```perl
my $rt = Algorithm::Kademlia::RoutingTable->new(
    local_id_bin => $my_id_bin,
    k            => 20
);
```

## `add_peer( $id_bin, $data )`

Adds a peer to the appropriate bucket.

- If the peer is already present, it is moved to the "most recently seen" position (the tail of the bucket).
- If the bucket is full (reaches size `k`), it returns the "least recently seen" peer (the head of the bucket). According to the Kademlia whitepaper, the caller should ping this stale peer.
- If the bucket is not full, the peer is added and it returns `undef`.

```perl
my $stale = $rt->add_peer($id, { ip => '1.2.3.4', port => 4444 });
if ($stale) {
    # Bucket full! Ping $stale->{data}{ip}
}
```

## `evict_peer( $id_bin )`

Removes a peer from the routing table. Usually called after a stale peer fails a ping check.

```
$rt->evict_peer($stale_id);
```

## `find_closest( $target_id_bin, [ $count ] )`

Returns a list of up to `$count` (defaults to `k`) peers closest to the target ID according to the XOR metric.

```perl
my @peers = $rt->find_closest($target_key, 10);
for my $peer (@peers) {
    say 'Node ' . unpack('H*', $peer->{id}) . ' is at ' . $peer->{data}{ip};
}
```

## `size( )`

Returns the total number of peers across all buckets.

```
say 'Routing table has ' . $rt->size . ' peers';
```

# Algorithm::Kademlia::Storage

A simple in-memory key-value store intended to hold the DHT data.

## `new( [ ttl => 86400 ] )`

Constructor. `ttl` is the time-to-live for entries in seconds.

```perl
my $storage = Algorithm::Kademlia::Storage->new( ttl => 3600 );
```

## `put( $key_bin, $value_bin, [ $publisher_id_bin ] )`

Stores a value.

```
$storage->put($cid_bin, $data_bin, $provider_id);
```

## `get( $key_bin )`

Retrieves a value. Returns `undef` if the key is missing or has expired.

```perl
my $data = $storage->get($cid_bin);
die 'Expired or not found' unless defined $data;
```

## `entries( )`

Returns a hash reference of all non-expired entries in the store.

```perl
my %all = $storage->entries();
for my ($key, $info) (%all) {
    say 'Key: ' . unpack('H*', $key) . ' Value: ' . $info->{value};
}
```

# Algorithm::Kademlia::Search

A state manager for the iterative Kademlia lookup algorithm. It tracks which nodes have been queried, which have
responded, and which have failed.

## `new( target_id_bin => ..., [ k => 20, alpha => 3 ] )`

Constructor. `alpha` is the concurrency parameter (how many parallel queries to allow).

```perl
my $search = Algorithm::Kademlia::Search->new(
    target_id_bin => $target_key,
    alpha         => 3
);
```

## `add_candidates( @peers )`

Adds new potential nodes to the search shortlist.

```
$search->add_candidates( $rt->find_closest($target_key) );
```

## `pending_queries( )`

Returns a list of nodes that have been queried but have not yet responded or failed.

```perl
my @waiting = $search->pending_queries();
say 'Waiting for ' . scalar(@waiting) . ' nodes...';
```

## `next_to_query( )`

Returns a list of up to `alpha` nodes that have not yet been queried, sorted by proximity to the target.

```perl
my @to_query = $search->next_to_query();
# Now send your RPCs to these nodes...
```

## `mark_responded( $id_bin, @new_peers )`

Marks a node as having responded and adds any new peers it returned to the shortlist.

```
# After getting a response from a FIND_NODE RPC:
$search->mark_responded($peer_id, @peers_from_rpc);
```

## `mark_failed( $id_bin )`

Marks a node as failed (e.g., RPC timeout).

```
# After a timeout or connection error:
$search->mark_failed($peer_id);
```

## `is_finished()`

Returns true if the search has reached a termination condition (either `k` nodes have responded, or there are no more
nodes to query and no pending requests).

```
while (!$search->is_finished) {
    # ... keep querying ...
}
```

## `best_results()`

Returns a list of the `k` closest nodes that successfully responded.

```perl
my @k_closest = $search->best_results();
```

# SEE ALSO

[InterPlanetary::Kademlia](https://metacpan.org/pod/InterPlanetary%3A%3AKademlia) (for the libp2p implementation)

[Net::BitTorrent::DHT](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ADHT) (for the BitTorrent implementation)

[https://xlattice.sourceforge.net/components/protocol/kademlia/specs.html](https://xlattice.sourceforge.net/components/protocol/kademlia/specs.html)

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# COPYRIGHT

Copyright (C) 2023-2026 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
