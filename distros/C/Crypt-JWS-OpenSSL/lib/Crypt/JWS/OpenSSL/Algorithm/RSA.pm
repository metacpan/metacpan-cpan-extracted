package Crypt::JWS::OpenSSL::Algorithm::RSA;
$Crypt::JWS::OpenSSL::Algorithm::RSA::VERSION = '0.005';
use Moo;
with qw(
    Crypt::JWS::OpenSSL::Role::Algorithm
    Crypt::JWS::OpenSSL::Role::Encoder
);
use Crypt::OpenSSL::Random 0.15;
use Crypt::OpenSSL::RSA 0.33;
use Crypt::OpenSSL::Bignum;
use Crypt::JWS::OpenSSL::Local;
use Digest::SHA;
use Carp qw( croak );
use namespace::clean;


my $RSA_ALGO_MAP = {
    'RS256'  => [ 'use_sha256_hash', 'use_pkcs1_padding' ],
    'RS384'  => [ 'use_sha384_hash', 'use_pkcs1_padding' ],
    'RS512'  => [ 'use_sha512_hash', 'use_pkcs1_padding' ],
    'PS256'  => [ 'use_sha256_hash', 'use_pkcs1_pss_padding' ],
    'PS384'  => [ 'use_sha384_hash', 'use_pkcs1_pss_padding' ],
    'PS512'  => [ 'use_sha512_hash', 'use_pkcs1_pss_padding' ],
};

has 'can_use_pkcs1_padding'     => ( is => 'lazy' );

has '_version_supports_pss'     => ( is => 'lazy' );

sub can_use_pkcs1_pss_padding {
    return ($_[0]->_version_supports_pss && $Crypt::JWS::OpenSSL::Local::HAS_OPENSSL3 ) ? 1 : 0;
}

sub sign {
    my( $self, $request) = parse_params(@_);
    my $algorithm = $request->{algorithm};
      
    my $keyref = ref( $request->{key} );
    my $rsa;
    
    if ($keyref) {
        if ( $keyref eq 'HASH' ) {
            my $keyparams = $self->_get_private_key_params( $request->{key} );
            $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( @$keyparams, 'check' => 1 );
        } else {
            croak 'invalid jwk reference';
        }
    } else {
        $rsa = Crypt::OpenSSL::RSA->new_private_key($request->{key});
    }
    for my $method ( @{ $RSA_ALGO_MAP->{$algorithm} } ) {
        $rsa->$method;
    }
    return $rsa->sign($request->{message});
}

sub verify {
    my( $self, $request) = parse_params(@_);
    my $algorithm = $request->{algorithm};
    my $keyref = ref( $request->{key} );
    my $rsa;
    
    if ($keyref) {
        if ( $keyref eq 'HASH' ) {
            my $keyparams = $self->_get_public_key_params( $request->{key} );
            $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters( @$keyparams );
        } else {
            croak 'invalid jwk reference';
        }
    } else {
        $rsa = Crypt::OpenSSL::RSA->new_public_key($request->{key});
    }
    for my $method ( @{ $RSA_ALGO_MAP->{$algorithm} } ) {
        $rsa->$method;
    }
    return $rsa->verify($request->{message}, $request->{signature}) ? 1 : 0;
}

sub _get_private_key_params {
    my( $self, $jwk) = @_;
    my ($n, $e, $d, $p, $q );
    
    my @bignums = ();
    
    if (exists($jwk->{'n'}) && defined($jwk->{'n'})) {
        $n = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'n'}));
    }
    
    if (exists($jwk->{'e'}) && defined($jwk->{'e'})) {
        $e = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'e'}));
    }
    
    if (exists($jwk->{'d'}) && defined($jwk->{'d'})) {
        $d = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'d'}));
    }
    
    if (exists($jwk->{'p'}) && defined($jwk->{'p'})) {
        $p = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'p'}));
    }
    
    if (exists($jwk->{'q'}) && defined($jwk->{'q'})) {
        $q = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'q'}));
    }
    
    if ( $n && $e && $d ) {
        push( @bignums, $n, $e, $d );
    } else {
        croak 'could not extract parameters from private RSA JWK'; 
    }
    
    if ( $p && $q ) {
        push( @bignums, $p, $q );
    } else {
        push( @bignums, undef, undef);
    }
    
    return \@bignums;
}

sub _get_public_key_params {
    my( $self, $jwk) = @_;
    my ( $n, $e, $d, $p, $q );
    
    if (exists($jwk->{'n'}) && defined($jwk->{'n'})) {
        $n = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'n'}));
    }
    
    if (exists($jwk->{'e'}) && defined($jwk->{'e'})) {
        $e = Crypt::OpenSSL::Bignum->new_from_bin($self->decode_jwk_element($jwk->{'e'}));
    }
    
    unless ( $n && $e ) {
        croak 'could not extract parameters from public RSA JWK'; 
    }
    
    my @bignums = ( $n, $e, $d, $p, $q );
    
    return \@bignums;
}

sub _build_can_use_pkcs1_padding {
    my $self = shift;
    my $_rsa_ver = $self->numify_version($Crypt::OpenSSL::RSA::VERSION);
    
    ### version 0.36 and 0.37 are broken
    if ( $_rsa_ver > 0.35 && $_rsa_ver < 0.38  ) {
        return 0;
    }
    
    ## this version works, but we must not call
    ## use_pkcs1_padding
    if ( $_rsa_ver == 0.35 ) {
        for my $algo ( 'RS256', 'RS384', 'RS512' ) {
            delete $RSA_ALGO_MAP->{$algo}->[1];
        }
    }
    
    ## apart from above versions >= 0.33 work
    return 1;
}

sub _build__version_supports_pss {
    my $self = shift;
    my $_rsa_ver = $self->numify_version($Crypt::OpenSSL::RSA::VERSION);
    return ( $_rsa_ver >= 0.36 ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL::Algorithm::RSA - Sign and verify tokens using RSA algorithms

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Crypt::JWS::OpenSSL::Algorithm::RSA;
  my $jws = Crypt::JWS::OpenSSL::Algorithm::RSA->new;
  
  my $token = $jws->sign(
    algorithm => 'RS256',
    key       => $rsa_private_key_pem_content,
    message   => join('.', $base64urlEncodedHeader, $base64urlEncodedClaims),
  );
    
  my $is_verified = $jws->verify(
    algorithm => 'RS256',
    key       => $rsa_public_key_pem_content,
    message   => join('.', $base64urlEncodedHeader, $base64urlEncodedClaims),
    signature => $base64urlDecodedSignature,
  );


=head1 DESCRIPTION

This module uses L<Crypt::OpenSSL::RSA> to sign and verify JWTs using
RSA digital signatures.

It is used within L<Crypt::JWS::OpenSSL> but it can be used directly
if you handle the Base64 url encoding and decoding elswhere.

=head1 METHODS

=head2 sign

  my $token = $jwt->sign(
    algorithm => $algo,
    key       => $key,
    message   => $message
  );

The method accepts an even numbered list or a hash reference. It returns a signature.

=over

=item C<algorithm>

The name of the algorithm supported by the C<key> parameter.

=item C<key>

The pem encoded RSA private key or a hash reference containing a JWK.

It is more efficient to convert a JWK to a pem encoded key and use that
for signing.

See L<Crypt::JWS::OpenSSL::Util::JWK>

=item C<message>

The Base64 url encoded JSON header and the Base64 url encoded JSON claims joined together with a '.' ( dot ).

=back

The final token is produced by Base64 encoding the signature returned by this method and adding it
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

The pem encoded RSA public key or a hash reference containing a JWK.

It is more efficient to convert the JWK to a pem encoded key and store
that if you expect to be verifying regularly with this public key.

See L<Crypt::JWS::OpenSSL::Util::JWK>

=item C<message>

The Base64 url encoded JSON header and the Base64 url encoded JSON claims joined together
with a '.' ( dot ) extracted from a token.

=item C<signature>

The Base64 url decoded raw signature extracted from the token.

=back

=head2 can_use_pkcs1_padding

  if( $jws->can_use_pkcs1_padding ) {
    .......
  }

The method returns true if RSASSA-PKCS-v1_5 padding is supported by your version
of Crypt::OpenSSL::RSA.

RSA signatures can use two types of padding, RSASSA-PKCS-v1_5 and RSASSA-PSS.

Algorithms RS256, RS384 and RS512 use RSASSA-PKCS-v1_5 padding.

Unless you have Crypt::OpenSSL::RSA versions 0.36 or 0.37, you will be able to
sign and verify tokens using these algorithms.

=head2 can_use_pkcs1_pss_padding

  if( $jws->can_use_pkcs1_pss_padding ) {
    .......
  }

The method returns true if RSASSA-PSS padding is supported by your version
of Crypt::OpenSSL::RSA and OpenSSL

RSA signatures can use two types of padding, RSASSA-PKCS-v1_5 and RSASSA-PSS.

Algorithms PS256, PS384 and PS512 use RSASSA-PSS.

You need Crypt::OpenSSL::RSA versions >= 0.36 and OpenSSL 3 to
sign and verify tokens using these algorithms.

=head1 ALGORITHMS

=over

=item RS256

C<RSASSA-PKCS-v1_5 using SHA-256>

Cannot be used with Crypt::OpenSSL::RSA versions 0.36 and 0.37

=item RS384

C<RSASSA-PKCS-v1_5 using SHA-384>

Cannot be used with Crypt::OpenSSL::RSA versions 0.36 and 0.37

=item RS512

C<RSASSA-PKCS-v1_5 using SHA-512>

Cannot be used with Crypt::OpenSSL::RSA versions 0.36 and 0.37

=item PS256

C<RSASSA-PSS using SHA-256 and MGF1 with SHA-256>

Needs Crypt::OpenSSL::RSA versions >= 0.36 and OpenSSL 3

=item PS384

C<RSASSA-PSS using SHA-384 and MGF1 with SHA-384>

Needs Crypt::OpenSSL::RSA versions >= 0.36 and OpenSSL 3

=item PS512

C<RSASSA-PSS using SHA-512 and MGF1 with SHA-512>

Needs Crypt::OpenSSL::RSA versions >= 0.36 and OpenSSL 3

=back

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
