use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Archive::CAR::v1 v0.0.3 {
    use Archive::CAR::Utils qw[systell];
    use CBOR::Free;
    use CBOR::Free::Decoder;
    #
    field $header : reader;
    field $roots  : reader;
    field $blocks : reader;
    #
    method version ()          {1}
    method to_file ($filename) { Archive::CAR->write( $filename, $self->roots, $self->blocks, 1 ) }

    method read ( $fh, $limit //= undef ) {
        my $data_start = systell($fh);

        # Header
        my ($header_len) = Archive::CAR::Utils::decode_varint($fh);
        return undef unless defined $header_len;
        my $header_raw;
        read( $fh, $header_raw, $header_len );
        $header = do {
            local $SIG{__WARN__} = sub {
                warn @_ unless $_[0] =~ /Ignoring unrecognized CBOR tag #42/;
            };
            CBOR::Free::decode($header_raw);
        };
        if ( $header->{roots} ) {
            my @roots_list;
            for my $root_data ( @{ $header->{roots} } ) {
                my $raw_cid = $root_data;
                open my $rfh, '<', \$raw_cid;
                push @roots_list, Archive::CAR::Utils::decode_cid($rfh);
            }
            $roots = \@roots_list;
        }
        my @blocks_list;
        while ( !defined $limit || systell($fh) < $data_start + $limit ) {
            my $record_start = systell($fh);
            my ( $block_len, $varint_len ) = Archive::CAR::Utils::decode_varint($fh);
            last unless defined $block_len;
            my $cid = Archive::CAR::Utils::decode_cid($fh);
            if ( !defined $cid ) {
                last;
            }
            my $cid_len  = length( $cid->raw );
            my $data_len = $block_len - $cid_len;
            if ( $data_len < 0 ) {
                last;
            }
            my $data;
            read( $fh, $data, $data_len );
            push @blocks_list,
                {
                cid         => $cid,
                data        => $data,
                offset      => $record_start,
                length      => $block_len + $varint_len,
                blockOffset => systell($fh) - $data_len,
                blockLength => $data_len,
                };
        }
        $blocks = \@blocks_list;
        return $self;
    }

    method write ( $fh, $roots, $blocks ) {

        # Write Header
        # Transform CID objects to CBOR tags for the header
        my @cbor_roots     = map { CBOR::Free::tag( 42, $_->raw ) } @$roots;
        my $header_data    = { version => 1, roots => \@cbor_roots, };
        my $header_encoded = CBOR::Free::encode($header_data);
        print {$fh} Archive::CAR::Utils::encode_varint( length($header_encoded) );
        print {$fh} $header_encoded;

        # Write Blocks
        for my $block (@$blocks) {
            my $cid_raw   = $block->{cid}->raw;
            my $data      = $block->{data};
            my $block_len = length($cid_raw) + length($data);
            print {$fh} Archive::CAR::Utils::encode_varint($block_len);
            print {$fh} $cid_raw;
            print {$fh} $data;
        }
    }
};
#
1;
