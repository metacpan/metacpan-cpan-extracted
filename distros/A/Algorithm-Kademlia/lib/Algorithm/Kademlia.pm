use v5.40;
use experimental 'class';
#
package Algorithm::Kademlia v1.0.0 {
    use parent 'Exporter';
    our @EXPORT_OK = qw[xor_distance xor_bucket_index];
    #
    sub xor_distance ( $id1_bin, $id2_bin ) { $id1_bin^.$id2_bin }

    sub xor_bucket_index ( $id1_bin, $id2_bin ) {
        my $dist  = $id1_bin^.$id2_bin;
        my @bytes = unpack( 'C*', $dist );
        my $len   = scalar @bytes;
        for my $i ( 0 .. $#bytes ) {
            next if $bytes[$i] == 0;
            my $byte = $bytes[$i];
            for ( my $j = 7; $j >= 0; $j-- ) {

                # Standard Kademlia: bucket i covers distance [2^i, 2^{i+1})
                return ( ( $len - 1 - $i ) * 8 ) + $j if $byte & ( 1 << $j );
            }
        }
        return undef;    # Same ID
    }
    class Algorithm::Kademlia::RoutingTable v1.0.0 {
        field $local_id_bin : param;
        field $k : param //= 20;
        field @buckets : reader;
        #
        ADJUST {
            my $id_len      = length $local_id_bin;
            my $num_buckets = $id_len * 8;
            @buckets = map { [] } 0 .. $num_buckets - 1
        }

        method add_peer ( $peer_id_bin, $peer_data ) {
            my $idx = Algorithm::Kademlia::xor_bucket_index( $local_id_bin, $peer_id_bin );
            return undef unless defined $idx;
            my $bucket = $buckets[$idx];

            # Find existing
            my $existing_idx = -1;
            for my $i ( 0 .. $#$bucket ) {
                if ( $bucket->[$i]{id} eq $peer_id_bin ) {
                    $existing_idx = $i;
                    last;
                }
            }
            if ( $existing_idx != -1 ) {    # Move to tail (most recent)
                my $peer = splice( @$bucket, $existing_idx, 1 );
                $peer->{data} = $peer_data;    # Update data
                push @$bucket, $peer;
                return undef;
            }
            if ( scalar @$bucket < $k ) {
                push @$bucket, { id => $peer_id_bin, data => $peer_data };
                return undef;
            }
            $bucket->[0];    # Bucket is full. Return oldest peer to be pinged.
        }

        method evict_peer ($peer_id_bin) {
            my $idx    = Algorithm::Kademlia::xor_bucket_index( $local_id_bin, $peer_id_bin ) // return;
            my $bucket = $buckets[$idx];
            @$bucket = grep { $_->{id} ne $peer_id_bin } @$bucket;
        }

        method find_closest ( $target_id_bin, $count = undef ) {
            $count //= $k;
            my @all_peers;
            push @all_peers, @$_ for @buckets;
            my @sorted = sort { ( $a->{id} ^.$target_id_bin ) cmp( $b->{id} ^.$target_id_bin ) } @all_peers;
            splice @sorted, 0, $count;
        }

        method size () {
            my $count = 0;
            $count += scalar @$_ for @buckets;
            $count;
        }
    };
    class Algorithm::Kademlia::Storage v1.0.0 {
        field %store : reader(entries);           # key_bin -> { value => val_bin, time => timestamp, publisher => id_bin }
        field $ttl : reader : param //= 86400;    # 24 hours

        method put ( $key_bin, $value_bin, $publisher_id_bin = undef ) {
            $store{$key_bin} = { value => $value_bin, time => time(), publisher => $publisher_id_bin };
        }

        method get ($key_bin) {
            my $entry = $store{$key_bin} or return undef;
            if ( time() - $entry->{time} > $ttl ) {
                delete $store{$key_bin};
                return undef;
            }
            $entry->{value};
        }
    };
    class Algorithm::Kademlia::Search v1.0.0 {
        field $target_id_bin : param;
        field $k     : param //= 20;
        field $alpha : param //= 3;
        field %nodes;    # id_bin -> { data => ..., queried => 0, responded => 0, failed => 0 }

        method add_candidates (@peers) {
            for my $peer (@peers) {
                my $id = $peer->{id};
                next if $nodes{$id} && ( $nodes{$id}{queried} || $nodes{$id}{failed} );
                $nodes{$id} //= { data => $peer->{data}, queried => 0, responded => 0, failed => 0 };
            }
        }

        method pending_queries () {
            grep { $_->{queried} && !$_->{responded} && !$_->{failed} } values %nodes;
        }

        method next_to_query () {
            my @sorted = sort { ( $a^.$target_id_bin ) cmp( $b^.$target_id_bin ) } keys %nodes;
            my @to_query;
            for my $id (@sorted) {
                next if $nodes{$id}{queried} || $nodes{$id}{failed};
                push @to_query, { id => $id, data => $nodes{$id}{data} };
                $nodes{$id}{queried} = 1;
                last if @to_query >= $alpha;
            }
            @to_query;
        }

        method mark_responded ( $id_bin, @new_peers ) {
            return unless $nodes{$id_bin};
            $nodes{$id_bin}{responded} = 1;
            $self->add_candidates(@new_peers);
        }

        method mark_failed ($id_bin) {
            return unless $nodes{$id_bin};
            $nodes{$id_bin}{failed} = 1;
        }

        method best_results () {
            my @sorted  = sort { ( $a^.$target_id_bin ) cmp( $b^.$target_id_bin ) } grep { $nodes{$_}{responded} } keys %nodes;
            my @results = map  { { id => $_, data => $nodes{$_}{data} } } splice( @sorted, 0, $k );
            @results;
        }

        method is_finished () {
            my @responded = grep { $_->{responded} } values %nodes;
            return 1 if @responded >= $k;
            my @available = grep { !$_->{queried} && !$_->{failed} } values %nodes;
            return 1 if !@available && !$self->pending_queries;
            0;
        }
    };
};
1;
