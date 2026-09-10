package Crypt::JWS::OpenSSL::Util::JWK;
$Crypt::JWS::OpenSSL::Util::JWK::VERSION = '0.005';
use Moo;
with qw(
    Crypt::JWS::OpenSSL::Role::Encoder
    Crypt::JWS::OpenSSL::Role::ECEncoder
);
use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::Bignum::CTX;
use Carp qw( croak );
use namespace::clean;

# All the EC curves we support have a fixed
# initial 4 bytes ( in hex )
#  P-256 PRIVATE  30770201
#  P-384 PRIVATE  3081A402
#  P-521 PRIVATE  3081DC02
#  P-256 PUBLIC   30593013
#  P-384 PUBLIC   30763010
#  P-521 PUBLIC   30819B30

my $ECC_ALGO_MAP = {
    'ES256' => [ 32, qr!\x04\x20(.{32})!s, 'P-256' ],
    'ES384' => [ 48, qr!\x04\x30(.{48})!s, 'P-384' ],
    'ES512' => [ 66, qr!\x04\x42(.{66})!s, 'P-521' ],
};

has '_version_supports_pkcs8_x509' => ( is => 'lazy' );

sub pem_to_jwk {
    my($self, $params) = parse_params(@_);
    
    croak 'no kid parameter provided' unless $params->{kid};
    croak 'no key parameter provided' unless $params->{key};
    
    my ($pemtype, $keytype ) = ( $params->{key} =~ m!-BEGIN( EC | RSA | )(PUBLIC|PRIVATE) KEY-!  );
    croak 'invalid or unsupported pem key type' unless( $pemtype && $keytype );
    $pemtype =~ s!\s+!!g;
    my $pembytes = $self->decode_pem($params->{key});
    my $checkbytes = uc(unpack('H*', substr($pembytes, 0, 4)));
    $params->{keytype} = $keytype;
    $params->{raw_key_ref} = \$pembytes;
    if ($keytype eq 'PRIVATE') {
        if ($pemtype eq 'EC') {
            if($checkbytes eq '30770201') {
                $params->{alg} = 'ES256';
            } elsif($checkbytes eq '3081A402') {
                $params->{alg} = 'ES384'
            } elsif($checkbytes eq '3081DC02') {
                $params->{alg} = 'ES512';
            } else {
                croak 'unable to parse EC private key';
            }
            return $self->_ecc_pem_to_jwk($params);
        } else {
            return $self->_rsa_pem_to_jwk($params);
        }
    } elsif( $keytype eq 'PUBLIC' ) {
        if ($checkbytes eq '30593013') {
            $params->{alg} = 'ES256';
        } elsif($checkbytes eq '30763010') {
            $params->{alg} = 'ES384';
        } elsif($checkbytes eq '30819B30') {
            $params->{alg} = 'ES512';
        } else {
            return $self->_rsa_pem_to_jwk($params);
        }
        return $self->_ecc_pem_to_jwk($params);
    }
    
    croak 'unable to parse pem encoded key';
}

sub jwk_to_pem {
    my($self, $jwk) = @_;
    my $kty = uc($jwk->{kty} || '');
    
    $kty ||= ( $jwk->{crv} ) ? 'EC' : 'RSA';
    
    unless( $kty =~ m!\AEC\Z|\ARSA\Z!) {
        croak "unsupported kty '$kty'";
    }
    
    if ( $kty eq 'EC') {
        return $self->_ecc_jwk_to_pem($jwk);
    } else {
        return $self->_rsa_jwk_to_pem($jwk);
    }
}

sub _rsa_pem_to_jwk {
    my($self, $params) = @_;
    
    my $alg = uc($params->{alg} || $params->{algo} || $params->{algorithm} || '');
    if ( $alg && $alg !~ m!^(R|P)S(256|384|512)$! ) {
        croak qq(invalid alg parameter '$alg');
    }
    
    my $kid = $params->{kid};
    
    my $jwk = $self->_extract_rsa_key_members($params->{keytype}, $params->{raw_key_ref});
    
    $jwk->{use} = 'sig';
    $jwk->{kty} = 'RSA';
    $jwk->{kid} = $kid;
    if ($alg) {
        $jwk->{alg} = $alg;
    }
    
    return $jwk;
}

sub _ecc_pem_to_jwk {
    my($self, $params) = @_;
    # mandatory public   crv x y
    # mandatory private  crv x y d
    # meta always add    kty use alg kid
    
    my ( $coord_len, $rx, $crv) = @{ $ECC_ALGO_MAP->{$params->{alg}} };
    
    my $jwk = $self->_extract_ecc_key_members(
        $params->{raw_key_ref}, $params->{keytype}, $rx, $coord_len, $params->{alg});
    
    $jwk->{use} = 'sig';
    $jwk->{kty} = 'EC';
    $jwk->{kid} = $params->{kid};
    $jwk->{alg} = $params->{alg};
    $jwk->{crv} = $crv;
        
    return $jwk;
}

sub _extract_rsa_key_members {
    my($self, $keytype, $raw_key_ref) = @_;
    
    my $rsa = ( $keytype eq 'PRIVATE' )
        ? Crypt::OpenSSL::RSA->new_private_key($$raw_key_ref)
        : Crypt::OpenSSL::RSA->new_public_key($$raw_key_ref);
    
    my ($n, $e, $d, $p, $q, $dp, $dq, $qi) = $rsa->get_key_parameters();
    
    my $enc_n  = (defined($n)) ? $self->encode_jwk_element($n->to_bin) : undef;
    my $enc_e  = (defined($e)) ? $self->encode_jwk_element($e->to_bin) : undef;
    my $enc_d  = (defined($d)) ? $self->encode_jwk_element($d->to_bin) : undef;
    my $enc_p  = (defined($p)) ? $self->encode_jwk_element($p->to_bin) : undef;
    my $enc_q  = (defined($q)) ? $self->encode_jwk_element($q->to_bin) : undef;
    my $enc_dp = (defined($dp)) ? $self->encode_jwk_element($dp->to_bin) : undef;
    my $enc_dq = (defined($dq)) ? $self->encode_jwk_element($dq->to_bin) : undef;
    my $enc_qi = (defined($qi)) ? $self->encode_jwk_element($qi->to_bin) : undef;
    
    unless(defined($enc_n) && defined($enc_e)) {
        croak 'unable to extract parameters n and e from the key';
    }
    
    if ( $keytype eq 'PUBLIC' ) {
        return { 'n' => $enc_n, 'e' => $enc_e };
    }
    
    unless(defined($enc_d)) {
        croak 'unable to extract parameter d from the private key';
    }
    
    my $jwk_params = { 'n' => $enc_n, 'e' => $enc_e, 'd' => $enc_d };
    
    if ( defined( $enc_p)  && defined( $enc_q ) ) {
        $jwk_params->{'p'} = $enc_p;
        $jwk_params->{'q'} = $enc_q;
    } else {
        return $jwk_params;
    }
    
    if ( defined( $enc_dp )
        && defined( $enc_dq )
        && defined( $enc_qi )
        ) {
        $jwk_params->{'dp'} = $enc_dp;
        $jwk_params->{'dq'} = $enc_dq;
        $jwk_params->{'qi'} = $enc_qi;
    }
    
    return $jwk_params;
}

sub _extract_ecc_key_members {
    my($self, $raw_key_ref, $keytype, $rx, $coord_len, $algo) = @_;
    
    my $jwk_params = {};
    
    if ($keytype eq 'PRIVATE') {
        if( $$raw_key_ref =~ $rx)  {
            my $d = $1;
            $jwk_params->{'d'} = $self->encode_jwk_element($d);
        } else {
            croak qq(the ECC private key does not appear to be for alg type $algo);
        }
    }
        
    my $raw_pub_points = substr($$raw_key_ref, - ( $coord_len * 2 ));
    my $x = substr($raw_pub_points, 0, $coord_len);
    my $y = substr($raw_pub_points, $coord_len, $coord_len);
    
    $jwk_params->{'x'} = $self->encode_jwk_element($x);
    $jwk_params->{'y'} = $self->encode_jwk_element($y);
    
    return $jwk_params;
}

sub _rsa_jwk_to_pem {
    my( $self, $jwk) = @_;
    
    my ($n, $e, $d, $p, $q);
    
    if (exists($jwk->{'n'}) && defined($jwk->{'n'})) {
        $n = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'n'}));
    }
    
    if (exists($jwk->{'e'}) && defined($jwk->{'e'})) {
        $e = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'e'}));
    }
    
    if (exists($jwk->{'d'}) && defined($jwk->{'d'})) {
        $d = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'d'}));
    } else {
        my $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e, $d, $p, $q );
        
        if ( $self->_version_supports_pkcs8_x509 ) {
            return $rsa->get_public_key_x509_string();
        } else {
            return $rsa->get_public_key_string();
        }
    }
    
    if (exists($jwk->{'p'}) && defined($jwk->{'p'}) && exists($jwk->{'q'}) && defined($jwk->{'q'})) {
        $p = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'p'}));
        $q = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'q'}));
    }
    
    my $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e, $d, $p, $q );
    
    if ( $self->_version_supports_pkcs8_x509 ) {
        return $rsa->get_private_key_pkcs8_string();
    } else {
        return $rsa->get_private_key_string();
    }
}

sub _ecc_jwk_to_pem {
    my( $self, $jwk) = @_;
    if ( exists( $jwk->{d} ) && defined( $jwk->{d} ) ){
        return $self->_ecc_jwk_to_private_pem( $jwk );
    } else {
        return $self->_ecc_jwk_to_public_pem( $jwk );
    }
    
}

sub _ecc_jwk_to_private_pem {
    my( $self, $jwk) = @_;
    
    my $curvekey = $jwk->{crv} || '';
    
    my $curve = $self->get_ecc_curve($curvekey);
        
    croak 'Unsupported or missing crv in JWK' if !$curve;
    
    my $size  = $curve->{size};
    
    unless(
           exists($jwk->{d}) && $jwk->{d}
           && exists($jwk->{x}) && $jwk->{x}
           && exists($jwk->{y}) && $jwk->{y}
           ) {
        croak 'jwk does not contain all parameters d, x and y';
    }
    
    # # convert Base64 to raw bytes and left pad
    my $d_bytes = $self->decode_jwk_element($jwk->{d});
    my $x_bytes = $self->decode_jwk_element($jwk->{x});
    my $y_bytes = $self->decode_jwk_element($jwk->{y});
    
    my $der_ref = $self->private_ecc_key_der($curvekey, $x_bytes, $y_bytes, $d_bytes );
    
    return $self->encode_ecc_private_key_pem($$der_ref);
    
}

sub _ecc_jwk_to_public_pem {
    my( $self, $jwk) = @_;
        
    my $curvekey = $jwk->{crv} || '';
    
    my $curve = $self->get_ecc_curve($curvekey);
    
    croak 'Unsupported or missing crv in JWK' if !$curve;
    
    unless(
           exists($jwk->{x}) && $jwk->{x}
           && exists($jwk->{y}) && $jwk->{y}
           ) {
        croak 'jwk does not contain all parameters x and y';
    }
    
    # convert Base64 to raw bytes and left pad
    my $x_bytes = $self->decode_jwk_element($jwk->{x});
    my $y_bytes = $self->decode_jwk_element($jwk->{y});
    
    my $der_ref = $self->public_ecc_key_der($curvekey, $x_bytes, $y_bytes );
    
    return $self->encode_ecc_public_key_pem($$der_ref);
    
}

sub _build__version_supports_pkcs8_x509 {
    my $self = shift;
    my $checkversion = $self->numify_version($Crypt::OpenSSL::RSA::VERSION);
    return ( $checkversion >= 0.38 ) ? 1 : 0;   
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL::Util::JWK - Utility to convert pem encoded keys to and from JWKs

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Crypt::JWS::OpenSSL::Util::JWK;
  my $util = Crypt::JWS::OpenSSL::Util::JWK;
  
  my $jwk = $util->pem_to_jwk( kid => 'my-kid-1', key => $pem_key_in );
  
  my $pem_key_out = $util->jwk_to_pem( $jwk );

=head1 DESCRIPTION

Utility to convert pem keys to JWKs and JWKs to pem keys

=head1 METHODS

=head2 pem_to_jwk( C<kid =E<gt> $kid, key =E<gt> $key, alg =E<gt> $rsa_alg> )

Returns a reference to a hash containing the structure of a JWK.

=head3 Parameters

=over

=item C<kid>

Required. Is added to the returned JWK ref as its unique indentifier.

=item C<key>

The text of a pem encoded key. For example

    -----BEGIN PUBLIC KEY-----
    MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEeXZBO6GGtqGAH1jAYVfutJdDTdISICoa
    3vMNBrm88aw3LGbDMGXfDbQvUREyN8oGj8yqNkU2yxZPD0n5z4Vxfo1OL49b6jpi
    QErHjC96K0+CmfypI5OXPbd+vpBlUAIj
    -----END PUBLIC KEY-----
  
=item C<alg>

If provided for an RSA key, it is added to the returned JWK hash.
The value is ignored for an ECC key.

=back

=head3 Return values

An RSA public key returns the hash ref structure

    {
        kid => '<kid input>',
        kty => 'RSA',
        use => 'sig',
        e   => '..........',
        n   => '..........'
    }

An RSA private key returns the hash ref structure

    {
        kid => '<kid input>',
        kty => 'RSA',
        use => 'sig',
        e   => '..........',
        n   => '..........',
        d   => '..........',
        p   => '..........',
        q   => '..........',
    }

Any RSA key can sign using any supported RSA algorithim. If the optional
C<alg> parameter is provided for an RSA key, an 'alg' will be added to
the returned JWK hash ref.

An ECC public key returns the hash ref structure ( for a P-384 curve )

    {
        kid => '<kid input>',
        kty => 'EC',
        use => 'sig',
        alg => 'ES384',
        crv => 'P-384'
        x   => '..........',
        y   => '..........'
    }

An ECC private key returns the hash ref structure ( for a P-521 curve )

    {
        kid => '<kid input>',
        kty => 'EC',
        use => 'sig',
        alg => 'ES512',
        crv => 'P-521'
        x   => '..........',
        y   => '..........',
        d   => '..........'
    }

=head2 jwk_to_pem( $jwk )

Converts a JWK to a pem encoded key

=head3 Parameter

=over

=item C<jwk>

A hash reference containing a JWK structure.

=back

=head3 Return value

Returns the text of a pem encoded key

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
