use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Archive::CAR::Indexer v0.0.4 {
    use Archive::CAR::Utils;

    # Simple index format (Format 0x0400: Multihash -> Offset)
    method generate_index ($blocks) {

        # Index Header
        # codec (varint)
        my $index_codec = 0x0400;                                             # IndexSorted
        my $data        = Archive::CAR::Utils::encode_varint($index_codec);

        # Format 0x0400:
        # bucket_count (uint32 LE)
        # For each bucket:
        #   digest_length (uint32 LE)
        #   entry_count (uint32 LE)
        #   entries: [digest (digest_length bytes), offset (uint64 LE)]
        # Group blocks by digest length
        my %buckets;
        for my $block (@$blocks) {
            my $digest = $block->{cid}->digest;
            push @{ $buckets{ length($digest) } }, $block;
        }
        my @sorted_lengths = sort { $a <=> $b } keys %buckets;
        $data .= pack( 'V', scalar @sorted_lengths );
        for my $len (@sorted_lengths) {
            my @sorted_blocks = sort { $a->{cid}->digest cmp $b->{cid}->digest } @{ $buckets{$len} };
            $data .= pack( 'V V', $len, scalar @sorted_blocks );
            for my $block (@sorted_blocks) {
                $data .= $block->{cid}->digest;
                $data .= pack( 'Q<', $block->{offset} );
            }
        }
        return $data;
    }
};
#
1;
