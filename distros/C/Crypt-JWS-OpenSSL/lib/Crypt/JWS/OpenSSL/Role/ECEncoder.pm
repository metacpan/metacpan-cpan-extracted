package Crypt::JWS::OpenSSL::Role::ECEncoder;
$Crypt::JWS::OpenSSL::Role::ECEncoder::VERSION = '0.005';
use Moo::Role;
use Carp qw( croak );

my $ECC_CURVES = {
    '1.2.840.10045.3.1.7' => { name => 'P-256', size => 32, oid => pack('C*', 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07) },
    '1.3.132.0.34'        => { name => 'P-384', size => 48, oid => pack('C*', 0x2B, 0x81, 0x04, 0x00, 0x22) },
    '1.3.132.0.35'        => { name => 'P-521', size => 66, oid => pack('C*', 0x2B, 0x81, 0x04, 0x00, 0x23) },
};

# General id-ecPublicKey OID: 1.2.840.10045.2.1
my $EC_PUBKEY_OID = pack('C*', 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01);

my $CURVE_KEY_TO_OID = {
    'P-256'      => '1.2.840.10045.3.1.7',
    'ES256'      => '1.2.840.10045.3.1.7',
    'secp256r1'  => '1.2.840.10045.3.1.7',
    'prime256v1' => '1.2.840.10045.3.1.7',
    'P-384'      => '1.3.132.0.34',
    'ES384'      => '1.3.132.0.34',
    'secp384r1'  => '1.3.132.0.34',
    'P-521'      => '1.3.132.0.35',
    'ES512'      => '1.3.132.0.35',
    'secp521r1'  => '1.3.132.0.35',
};

sub get_ecc_curve {
    my($self, $curvekey) = @_;
    if ($curvekey && exists($CURVE_KEY_TO_OID->{$curvekey}) ) {
        my $oid_string = $CURVE_KEY_TO_OID->{$curvekey};
        my $curve = { %{ $ECC_CURVES->{$oid_string} } };
        return $curve;
    }
    return undef;
}

sub public_ecc_key_der {
    my( $self, $curvekey, $x_bytes, $y_bytes) = @_;
    my $curve = $self->get_ecc_curve($curvekey);
    
    croak 'Unsupported or missing curve identifier' if !$curve;
    
    my $size = $curve->{size};
    
    substr( $x_bytes, 0, 0, "\x00" x ($size - length $x_bytes) );
    substr( $y_bytes, 0, 0, "\x00" x ($size - length $y_bytes) );
    
    # Build AlgorithmIdentifier Sequence
    my $alg_oid_tlv   = pack("CC", 0x06, length($EC_PUBKEY_OID)) . $EC_PUBKEY_OID;
    my $curve_oid_tlv = pack("CC", 0x06, length($curve->{oid})) . $curve->{oid};
    my $alg_id_payload = $alg_oid_tlv . $curve_oid_tlv;
    my $alg_id_seq     = pack("C", 0x30) . $self->_encode_asn1_length(length($alg_id_payload)) . $alg_id_payload;
    
    # Build Public Key Bit String Payload
    my $public_point = pack("C", 0x04) . $x_bytes . $y_bytes; # 0x04 prefix
    my $bit_str_body = pack("C", 0x00) . $public_point;       # 0x00 unused bits indicator
    my $pub_key_bits = pack("C", 0x03) . $self->_encode_asn1_length(length($bit_str_body)) . $bit_str_body;
    
    # Assemble Complete Outer SPKI Sequence
    my $spki_payload = $alg_id_seq . $pub_key_bits;
    my $der = pack("C", 0x30) . $self->_encode_asn1_length(length($spki_payload)) . $spki_payload;
    
    return \$der;
}

sub private_ecc_key_der {
    my( $self, $curvekey, $x_bytes, $y_bytes, $d_bytes) = @_;
    
    my $curve = $self->get_ecc_curve($curvekey);
    
    croak 'Unsupported or missing curve identifier' if !$curve;
    
    my $size = $curve->{size};
    
    substr( $d_bytes, 0, 0, "\x00" x ($size - length $d_bytes) );
    substr( $x_bytes, 0, 0, "\x00" x ($size - length $x_bytes) );
    substr( $y_bytes, 0, 0, "\x00" x ($size - length $y_bytes) );
    
    # Build explicit Parameters Tag [0] (0xA0)
    my $oid_tlv = pack("CC", 0x06, length($curve->{oid})) . $curve->{oid};
    my $tag0    = pack("C", 0xA0) . $self->_encode_asn1_length(length($oid_tlv)) . $oid_tlv;
    
    # Build explicit Public Key Tag [1] (0xA1)
    # Combines: Uncompressed point prefix (0x04) + X coordinates + Y coordinates
    my $pub_points   = pack("C", 0x04) . $x_bytes . $y_bytes;
    my $bit_str_body = pack("C", 0x00) . $pub_points; # 0x00 indicates zero unused bits
    my $bit_str_tlv  = pack("C", 0x03) . $self->_encode_asn1_length(length($bit_str_body)) . $bit_str_body;
    my $tag1         = pack("C", 0xA1) . $self->_encode_asn1_length(length($bit_str_tlv)) . $bit_str_tlv;
    
    # Assemble the internal ECPrivateKey payload sequence elements
    my $version_tlv   = pack("C3", 0x02, 0x01, 0x01);
    my $priv_key_tlv  = pack("C", 0x04) . $self->_encode_asn1_length(length($d_bytes)) . $d_bytes;
    
    my $sequence_payload = $version_tlv . $priv_key_tlv . $tag0 . $tag1;
    my $der = pack("C", 0x30) . $self->_encode_asn1_length(length($sequence_payload)) . $sequence_payload;
    
    return \$der;
}

sub _encode_asn1_length {
    my ($self, $len) = @_;
    if ($len < 128) {
        return pack("C", $len);
    }
    my @bytes;
    while ($len > 0) {
        unshift @bytes, ($len & 0xFF);
        $len >>= 8;
    }
    return pack("CC*", 0x80 | scalar(@bytes), @bytes);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL::Role::ECEncoder - Provides methods for modules handling EC curves.

Composed into

=over

=item

L<Crypt::JWS::OpenSSL::Util::JWK>

=item

L<Crypt::JWS::OpenSSL::Util::PEM>

=back

=head1 VERSION

version 0.005

=head1 METHODS

=head2 get_ecc_curve

Accepts a common curve descriptive string ( e.g P-384, ES256, secp521r1 )
and returns the necessary parameters to process a curve of that type.

=head2 private_ecc_key_der

Accepts a common curve descriptive string and the x, y and d
parameters of an EC private key. Returns the der encoded result.

=head2 public_ecc_key_der

Accepts a common curve descriptive string and the x and y 
parameters of an EC public key. Returns the der encoded result.

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
