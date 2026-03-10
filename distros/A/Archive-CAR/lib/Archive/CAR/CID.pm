use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Archive::CAR::CID v0.0.3 {
    use Archive::CAR::Utils qw[systell];
    #
    field $version : param : reader;
    field $codec   : param : reader;
    field $hash    : param : reader;
    field $digest  : param : reader;
    field $raw     : param : reader;
    #
    method to_string() {

        # Minimal string conversion for debugging/display
        # In a real IPFS context, this uses Multibase (base32 or base58)
        return 'b' . $self->_encode_base32($raw) if $version == 1;
        return unpack( 'H*', $raw );
    }

    method _encode_base32 ($data) {
        my @alphabet = split //, 'abcdefghijklmnopqrstuvwxyz234567';
        my $bits     = '';
        for my $byte ( unpack 'C*', $data ) {
            $bits .= sprintf '%08b', $byte;
        }
        my $out = '';
        while ( $bits =~ s/^([01]{5})// ) {
            $out .= $alphabet[ oct "0b$1" ];
        }
        if ( length $bits ) {
            $bits .= '0' x ( 5 - length $bits );
            $out  .= $alphabet[ oct "0b$bits" ];
        }
        return $out;
    }

    sub decode ( $class, $fh ) {
        my $pos_before = systell($fh);
        my $first_byte;
        my $fb_res = read( $fh, $first_byte, 1 );
        return undef unless defined $fb_res && $fb_res == 1;
        my $fb = ord($first_byte);
        if ( $fb == 0x00 ) {    # Optional leading zero
            $pos_before = systell($fh);
            $fb_res     = read( $fh, $first_byte, 1 );
            return undef unless defined $fb_res && $fb_res == 1;
            $fb = ord($first_byte);
        }
        if ( $fb == 0x12 ) {    # Likely CIDv0 in binary form
            my $second_byte;
            read( $fh, $second_byte, 1 );
            if ( defined $second_byte && ord($second_byte) == 0x20 ) {
                my $digest;
                read( $fh, $digest, 32 );
                my $raw = chr(0x12) . chr(0x20) . $digest;
                return $class->new( version => 0, codec => 0x70, hash => 0x12, digest => $digest, raw => $raw );
            }
            seek( $fh, $pos_before + 1, 0 );
        }
        seek( $fh, $pos_before, 0 );
        my ($version) = Archive::CAR::Utils::decode_varint($fh);
        return undef if !defined $version;
        my ($codec) = Archive::CAR::Utils::decode_varint($fh);
        return undef unless defined $codec;
        my ($mh_type) = Archive::CAR::Utils::decode_varint($fh);
        return undef unless defined $mh_type;
        my ($mh_len) = Archive::CAR::Utils::decode_varint($fh);
        return undef unless defined $mh_len;
        my $digest;
        read( $fh, $digest, $mh_len );
        my $pos_after = systell($fh);
        seek( $fh, $pos_before, 0 );
        my $raw;
        read( $fh, $raw, $pos_after - $pos_before );
        seek( $fh, $pos_after, 0 );
        return $class->new( version => $version, codec => $codec, hash => $mh_type, digest => $digest, raw => $raw );
    }

    sub from_raw ( $class, $raw ) {
        open my $fh, '<:raw', \$raw;
        return $class->decode($fh);
    }
};
#
1;
