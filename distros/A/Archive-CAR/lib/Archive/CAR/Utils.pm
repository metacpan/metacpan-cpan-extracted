use v5.40;
#
package Archive::CAR::Utils v0.0.4 {
    use Exporter 'import';
    our @EXPORT_OK = qw[encode_varint decode_varint decode_cid systell];
    #
    sub systell ($fh) {
        return tell($fh);
    }

    sub encode_varint ($val) {
        my $out = '';
        while ( $val >= 0x80 ) {
            $out .= chr( ( $val & 0x7f ) | 0x80 );
            $val >>= 7;
        }
        $out .= chr($val);
        return $out;
    }

    sub decode_varint ( $str_or_fh, $offset //= 0 ) {
        use Scalar::Util qw[openhandle];

        # Handles both scalar strings and filehandles
        my $is_fh = openhandle($str_or_fh);
        my ( $val, $shift, $bytes_read ) = ( 0, 0, 0 );
        my $initial_offset = $offset;
        while (1) {
            my $byte_val;
            if ($is_fh) {
                my $byte_char;
                my $bytes_read_now = read( $str_or_fh, $byte_char, 1 );
                return ( undef, 0 ) unless defined $bytes_read_now && $bytes_read_now == 1;
                $byte_val = ord($byte_char);
            }
            else {
                return ( undef, 0 ) unless $offset < length($str_or_fh);
                $byte_val = ord( substr( $str_or_fh, $offset++, 1 ) );
            }
            $bytes_read++;
            $val |= ( $byte_val & 0x7f ) << $shift;
            return ( $val, $bytes_read ) unless $byte_val & 0x80;
            $shift += 7;
            return ( undef, $bytes_read ) if $shift >= 64;
        }
    }

    sub decode_cid ($fh) {
        require Archive::CAR::CID;
        return Archive::CAR::CID->decode($fh);
    }
};
#
1;
