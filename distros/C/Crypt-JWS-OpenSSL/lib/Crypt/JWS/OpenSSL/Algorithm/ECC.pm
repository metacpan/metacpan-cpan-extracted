package Crypt::JWS::OpenSSL::Algorithm::ECC;
$Crypt::JWS::OpenSSL::Algorithm::ECC::VERSION = '0.005';
use Moo;
with qw(
  Crypt::JWS::OpenSSL::Role::Algorithm
  Crypt::JWS::OpenSSL::Role::Encoder
);
use Crypt::OpenSSL::Random 0.15;
use Crypt::OpenSSL::EC 1.32;
use Crypt::OpenSSL::ECDSA 0.10;
use Crypt::OpenSSL::Bignum 0.09;
use Crypt::OpenSSL::Bignum::CTX;
use Digest::SHA;
use Carp qw( croak );
use namespace::clean;

my $ECC_ALGO_MAP = {
    'ES256' => [ \&Digest::SHA::sha256, 'prime256v1', 32, 415, qr!\x04\x20(.{32})!s, \&Digest::SHA::hmac_sha256 ],
    'ES384' => [ \&Digest::SHA::sha384, 'secp384r1',  48, 715, qr!\x04\x30(.{48})!s, \&Digest::SHA::hmac_sha384 ],
    'ES512' => [ \&Digest::SHA::sha512, 'secp521r1',  66, 716, qr!\x04\x42(.{66})!s, \&Digest::SHA::hmac_sha512 ],
};

sub can_do_non_deterministic { 1 }
sub can_do_deterministic { 1 }

sub sign {
    my( $self, $request) = parse_params(@_);
    my $algorithm = $request->{algorithm};    
    my ($hash_method, $curve, $coord_len, $nid, $priv_key_qr, $hmac_method, $qlen ) = @{ $ECC_ALGO_MAP->{$algorithm} };
    
    my $key_ref = ref($request->{key});
    
    my $hex_private_key;
    
    if ( $key_ref )  {
        if ( $key_ref eq 'HASH' && exists($request->{key}->{d}) ) {
            my $keybin = $self->decode_jwk_element($request->{key}->{d});
            $hex_private_key = unpack("H*", $keybin);
        } else {
            croak 'failed to parse private key';
        }
    } else {
        $hex_private_key = $self->_load_private_key_as_hex($request->{key}, $priv_key_qr );
    }
        
    unless( $hex_private_key ) {
        croak "Could not extract a ${coord_len}-byte private key scalar from the private key";
    }
            
    my $ecc_key = Crypt::OpenSSL::EC::EC_KEY::new_by_curve_name($nid);
    die "Failed to initialize EC_KEY for curve NID $curve" unless $ecc_key;
    
    unless(Crypt::OpenSSL::EC::EC_KEY::set_private_key(
            $ecc_key, Crypt::OpenSSL::Bignum->new_from_hex($hex_private_key)
        )
    ) {
        croak "Failed to set private key on the EC_KEY object.";
    }
            
    my $digest = $hash_method->($request->{message});
    
    my $sig_obj;
        
    if ( $request->{non_deterministic} ) {
        $sig_obj = Crypt::OpenSSL::ECDSA::ECDSA_do_sign($digest, $ecc_key)
            or croak "Signing failed";
    } else {
        my $group = Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name($nid);
        my $ctx   = Crypt::OpenSSL::Bignum::CTX->new();
        my $q     = Crypt::OpenSSL::Bignum->new;
        Crypt::OpenSSL::EC::EC_GROUP::get_order($group, $q, $ctx)
            or croak 'failed to initialize curve order';
        
        my $k = _generate_k(
            $q->to_hex,
            $hex_private_key,
            $digest,
            $hmac_method,
            $coord_len,
            $q->num_bits
        );
                
        # Calculate kinv
        my $q_minus_two = $q->sub(Crypt::OpenSSL::Bignum->new_from_word(2));
        my $kinv        = $k->mod_exp($q_minus_two, $q, $ctx);
        
        # Calculate rp
        my $R = Crypt::OpenSSL::EC::EC_POINT::new($group);
        Crypt::OpenSSL::EC::EC_POINT::mul($group, $R, $k, \0, \0, $ctx);
        
        my $rx = Crypt::OpenSSL::Bignum->new();
        my $ry = Crypt::OpenSSL::Bignum->new();
        
        Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $R, $rx, $ry, $ctx);
        
        my (undef, $rp) = $rx->div($q, $ctx);
        
        $sig_obj = Crypt::OpenSSL::ECDSA::ECDSA_do_sign_ex($digest, $kinv, $rp, $ecc_key)
            or croak "Signing failed";
    }
        
    my $r_oct = $sig_obj->get_r();
    my $s_oct = $sig_obj->get_s();
    
    # pack r and s to correct length with leading bytes
    
    $r_oct = pack("a$coord_len", ("\x00" x ($coord_len - length($r_oct))) . $r_oct);
    $s_oct = pack("a$coord_len", ("\x00" x ($coord_len - length($s_oct))) . $s_oct);
    
    my $signature = $r_oct . $s_oct;
    
    return $signature;
}

sub verify {
    my( $self, $request) = parse_params(@_);
        
    my $algorithm = $request->{algorithm};
        
    my ($hash_method, $curve, $coord_len, $nid, $priv_key_qr, $hmac_method ) = @{  $ECC_ALGO_MAP->{$algorithm} };
    
    my $key_ref = ref($request->{key});
    
    my ( $pub_x_bin, $pub_y_bin );
    
    if ($key_ref) {
        if ($key_ref eq 'HASH' && exists($request->{key}->{x}) && exists($request->{key}->{y})) {
            $pub_x_bin = $self->decode_jwk_element($request->{key}->{x});
            $pub_y_bin = $self->decode_jwk_element($request->{key}->{y});
            $pub_x_bin = undef unless( length($pub_x_bin) == $coord_len);
            $pub_y_bin = undef unless( length($pub_y_bin) == $coord_len);
        }
    } else {
        my $p_key_bytes = $self->decode_pem($request->{key});
        my $raw_pub_points = substr($p_key_bytes, - ( $coord_len * 2 ));
        $pub_x_bin = substr($raw_pub_points, 0, $coord_len);
        $pub_y_bin = substr($raw_pub_points, $coord_len, $coord_len);
    }
    
    unless( $pub_x_bin && $pub_y_bin ) {
        croak 'failed to parse public key';
    }
    
    my $digest = $hash_method->($request->{message});
    
    my $group = Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name($nid);
    my $ecc_key = Crypt::OpenSSL::EC::EC_KEY::new();
    Crypt::OpenSSL::EC::EC_KEY::set_group($ecc_key, $group);
    
    # Populate Public Key Point
    my $x_bn  = Crypt::OpenSSL::Bignum->new_from_bin($pub_x_bin);
    my $y_bn  = Crypt::OpenSSL::Bignum->new_from_bin($pub_y_bin);
    my $point = Crypt::OpenSSL::EC::EC_POINT::new($group);
    
    my $ctx = Crypt::OpenSSL::Bignum::CTX->new();
    
    Crypt::OpenSSL::EC::EC_POINT::set_affine_coordinates_GFp($group, $point, $x_bn, $y_bn, $ctx)
        || croak "Failed to map point coordinates";
    Crypt::OpenSSL::EC::EC_KEY::set_public_key($ecc_key, $point)
        || croak "Failed to assign public key";
    
    my $r_bin = substr($request->{signature}, 0, $coord_len);
    my $s_bin = substr($request->{signature}, $coord_len, $coord_len);
    
    my $ecdsa_sig = Crypt::OpenSSL::ECDSA::ECDSA_SIG->new();
    
    $ecdsa_sig->set_r($r_bin);
    $ecdsa_sig->set_s($s_bin);
    
    my $result = Crypt::OpenSSL::ECDSA::ECDSA_do_verify( $digest, $ecdsa_sig, $ecc_key );
    
    if ( $result && $result eq '1') {
        return 1;
    } else {
        return 0;
    }
}

sub _load_private_key_as_hex {
    my($self, $pem, $rx) = @_;
    my $raw_key = $self->decode_pem($pem);
    my $hex_private_key;
    if( $raw_key =~ $rx)  {
        $hex_private_key = unpack("H*", $1);
    }
    return $hex_private_key;
}

sub _generate_k {
    my ($curve_order_hex, $private_key_hex, $digest, $hmac_method, $bytelen, $bitlen) = @_;
    my $order = Crypt::OpenSSL::Bignum->new_from_hex($curve_order_hex);
    my $key   = Crypt::OpenSSL::Bignum->new_from_hex($private_key_hex);
    
    my $curve = {
        q       => $order,
        bitlen  => $bitlen,
        bytelen => $bytelen,
    };
    
    my $privkey_bytes = $key->to_bin();
    
    substr( $privkey_bytes, 0, 0, "\x00" x ($curve->{'bytelen'} - length $privkey_bytes) );
    
    my $hash_len = length $digest;
    
    # Initialize cryptographic components V and K
    my $V = "\x01" x $hash_len;
    my $K = "\x00" x $hash_len;
    
    my $digest_octets = _bits2octets($digest, $curve );
        
    # Spin the HMAC state using the raw key string components
    $K = $hmac_method->( $V . "\x00" . $privkey_bytes . $digest_octets, $K );
    $V = $hmac_method->( $V, $K );
    $K = $hmac_method->( $V . "\x01" . $privkey_bytes . $digest_octets, $K );
    $V = $hmac_method->( $V, $K );
    
    # a Bignum with a value of 1
    my $bn_one = Crypt::OpenSSL::Bignum->one; 
    
    # Generation loop
    
    while (1) {
        my $T = '';
        while (1) {
            $V = $hmac_method->( $V, $K );
            $T .= $V;
            last if length($T) * 8 >= $curve->{'bitlen'};
        }
        
        my $k_candidate = _bits2int($T, $curve);
        
        ## rfc6979 allowed range between 1 and q -1
        ## 
        ## $bn_a->cmp($bn_b);
        ## returns:
        ## -1 if $bn_a <  bn_b
        ##  0 if $bn_a == bn_b
        ##  1 if $bn_a >  bn_b
        
        if (   $k_candidate->cmp($bn_one) > -1          # $k_candidate is equal to or greater than 1
            && $k_candidate->cmp($curve->{'q'}) == -1 ) # $k_candidate is less than q
        {
            return $k_candidate;
        }
        
        # If outside boundaries, stir the HMAC key ring state and repeat
        $K = $hmac_method->( $V . "\x00", $K );
        $V = $hmac_method->( $V, $K );
    }
}


## Bit String to Integer
## bits2int
## rfc6979 section-2.3.2

sub _bits2int {
    my ( $bytes, $curve ) = @_;
    my $bignum = Crypt::OpenSSL::Bignum->new_from_bin( $bytes );
    my $blen = 8 * length($bytes);
    if ($curve->{'bitlen'} < $blen) {
        my $rshift = $blen - $curve->{'bitlen'};
        return $bignum->rshift($rshift);
    }
    return $bignum;
}

## Integer to Octet String
## int2octets
## rfc6979 section-2.3.3

sub _int2octets {
    my ( $octets, $curve ) = @_;
    if (length($octets) > $curve->{'bytelen'}) {
        substr( $octets, 0, -$curve->{'bytelen'} ) = '';
    }
    elsif (length($octets) < $curve->{'bytelen'}) {
        substr( $octets, 0, 0, "\x00" x ($curve->{'bytelen'} - length $octets) );
    }
    return $octets;
}

## Bit String to Octet String
## bits2octets
## rfc6979 section-2.3.4

sub _bits2octets {
    my ( $bits, $curve ) = @_;
    my $z1 = _bits2int($bits, $curve);
    my $ctx = Crypt::OpenSSL::Bignum::CTX->new;
    my $z2 = $z1->copy->mod($curve->{'q'}, $ctx );
    return _int2octets($z2->to_bin, $curve);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL::Algorithm::ECC - Sign and verify tokens using ECDSA algorithms

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Crypt::JWS::OpenSSL::Algorithm::ECC;
  my $jws = Crypt::JWS::OpenSSL::Algorithm::ECC->new;
  
  my $token_1 = $jws->sign(
    algorithm => 'ES384',
    key       => $secp384r1_private_key_pem_content,
    message   => join('.', $base64urlEncodedHeader, $base64urlEncodedClaims),
  );
  
  my $token2 = $jws->sign(
    algorithm     => 'ES256',
    key           => $prime256v1_private_key_pem_content,
    message       => join('.', $base64urlEncodedHeader, $base64urlEncodedClaims),
    deterministic => 1
  );
  
  my $is_verified_1 = $jws->verify(
    algorithm => 'ES384',
    key       => $secp384r1_public_key_pem_content,
    message   => join('.', $base64urlEncodedHeader, $base64urlEncodedClaims),
    signature => $base64urlDecodedSignature,
  );
  
  my $is_verified_2 = $jws->verify(
    algorithm => 'ES256',
    key       => $prime256v1_public_key_pem_content,
    message   => join('.', $base64urlEncodedHeader, $base64urlEncodedClaims),
    signature => $base64urlDecodedSignature,
  );

=head1 DESCRIPTION

This module uses L<Crypt::OpenSSL::ECDSA> in combination with L<Crypt::OpenSSL::EC>
to sign and verify JWTs using elliptic curve digital signatures.

It is used within L<Crypt::JWS::OpenSSL> but it can be used directly
if you handle the Base64 url encoding and decoding elswhere.

=head1 METHODS

=head2 sign

  my $token = $jwt->sign(
    algorithm => $algo,
    key       => $key,
    message   => $message
  );
  
  my $token_2 = $jwt->sign(
    algorithm         => $algo,
    key               => $key,
    message           => $message,
    non_deterministic => 1,
  );

The method accepts an even numbered list or a hash reference. It returns a signature.

By default, the deterministic signing method is used.

=over

=item C<algorithm>

The name of the algorithm supported by the C<key> parameter.

=item C<key>

The pem encoded ECDSA private key or a hash reference containing a JWK.

It is more efficient to convert a JWK to a pem encoded key and use that
for signing.

See L<Crypt::JWS::OpenSSL::Util::JWK>

=item C<message>

The Base64 url encoded JSON header and the Base64 url encoded JSON claims joined together with a '.' ( dot ).

=item C<non_deterministic>

Set this value to 1 to sign using the non-deterministic method.

ECDSA signatures can created using either randomly generated parameters ( non-deterministic ) or
calculating parameters from message content and the private key ( deterministic ).

The difference between non-deterministic and deterministic ECDSA signatures lies
in how they generate a critical single-use nonce.

Non-deterministic (classic) ECDSA is notoriously fragile because it relies on a perfect
random number generator. If that generator fails and a nonce is ever repeated or guessed,
an attacker can steal the private key instantly. Deterministic ECDSA (RFC 6979) solves this
by deriving the nonce mathematically from the message and the private key, entirely removing
the need for a live random number generator during signing.

=back

The final token is produced by Base64 encoding the raw signature returned by this method and adding it
to the C<message> seperated by a '.' ( dot );

This method returns a raw signature.

=head2 verify

  my $is_verified = $jwt->verify(
    algorithm => $algo,
    key       => $key,
    message   => $message,
    signature => $raw_signature
  );

The method accepts an even numbered list or a hash reference.

It returns true if C<signature> matches a signature produced for the message by C<key>, or false if not.

=over

=item C<algorithm>

The name of the algorithm supported by the C<key> parameter.

=item C<key>

The pem encoded ECDSA private key or a hash reference containing a JWK.

It is more efficient to convert the JWK to a pem encoded key and store
that if you expect to be verifying regularly with this public key.

See L<Crypt::JWS::OpenSSL::Util::JWK>

=item C<message>

The Base64 url encoded JSON header and the Base64 url encoded JSON claims joined together
with a '.' ( dot ) extracted from a token.

=item C<signature>

The Base64 url decoded raw signature extracted from the token.

=back

=head1 ALGORITHMS

=over

=item ES256

C<ECDSA using P-256 ( prime256v1 ) and SHA-256>

=item ES384

C<ECDSA using P-384 ( secp384r1 ) and SHA-384>

=item ES512

C<ECDSA using P-521 ( secp521r1 ) and SHA-512>

=back

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
