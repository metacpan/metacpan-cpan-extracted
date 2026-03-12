use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Archive::CAR::v1 v0.0.4 {
    use Archive::CAR::Utils qw[systell];
    use Codec::CBOR;
    use Archive::CAR::CID;
    #
    field $header : reader;
    field $roots  : reader;
    field $blocks : reader;
    field $codec;
    #
    ADJUST {
        $codec = Codec::CBOR->new();
        $codec->add_tag_handler(
            42 => sub ($data) {

                # Codec::CBOR returns raw bytes for Major Type 2
                return Archive::CAR::CID->from_raw( substr( $data, 1 ) ) if substr( $data, 0, 1 ) eq "\x00";
                return Archive::CAR::CID->from_raw($data);
            }
        );
        $codec->add_class_handler(
            'Archive::CAR::CID' => sub ( $codec_obj, $item ) {
                my $cid_raw = $item->raw;
                return pack( 'C', 0xd8 ) . pack( 'C', 42 ) . $codec_obj->_encode_bytes( "\x00" . $cid_raw );
            }
        );
    }
    method version ()          {1}
    method to_file ($filename) { Archive::CAR->write( $filename, $self->roots, $self->blocks, 1 ) }

    method read ( $fh, $limit //= undef ) {
        my $data_start = systell($fh);

        # Header
        my ($header_len) = Archive::CAR::Utils::decode_varint($fh);
        return undef unless defined $header_len;
        my $header_raw;
        read( $fh, $header_raw, $header_len );
        $header = $codec->decode($header_raw);

        # Ensure roots are CID objects.
        # If they were decoded as Tag 42 with our handler, they already are.
        $roots = $header->{roots} if $header->{roots};
        my @blocks_list;
        while ( !defined $limit || systell($fh) < $data_start + $limit ) {
            my $record_start = systell($fh);
            my ( $block_len, $varint_len ) = Archive::CAR::Utils::decode_varint($fh);
            last unless defined $block_len;
            my $cid = Archive::CAR::Utils::decode_cid($fh);
            last unless defined $cid;
            my $cid_len  = length( $cid->raw );
            my $data_len = $block_len - $cid_len;
            last if $data_len < 0;
            my $data;
            read( $fh, $data, $data_len );
            push @blocks_list,
                {
                cid         => $cid,
                data        => $data,
                offset      => $record_start,
                length      => $block_len + $varint_len,
                blockOffset => systell($fh) - $data_len,
                blockLength => $data_len
                };
        }
        $blocks = \@blocks_list;
        return $self;
    }

    method write ( $fh, $roots, $blocks ) {

        # Write header
        # Transform CID objects to Tag 42 for the header via class handler
        my $header_data    = { version => 1, roots => $roots, };
        my $header_encoded = $codec->encode($header_data);
        print {$fh} Archive::CAR::Utils::encode_varint( length($header_encoded) );
        print {$fh} $header_encoded;

        # Write blocks
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
