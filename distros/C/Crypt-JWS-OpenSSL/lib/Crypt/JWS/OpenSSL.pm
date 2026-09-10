package Crypt::JWS::OpenSSL;
$Crypt::JWS::OpenSSL::VERSION = '0.005';
use v5.8.9;
use Moo 2.004003;
with qw( Crypt::JWS::OpenSSL::Role::Encoder );
use Crypt::JWS::OpenSSL::Algorithm::RSA;
use Crypt::JWS::OpenSSL::Algorithm::ECC;
use Crypt::JWS::OpenSSL::Algorithm::HMAC;
use Try::Tiny;
use Digest::SHA;
use Carp qw(croak confess);
use namespace::clean;

my $ALGO_MAP = {
    'HS256' => [ 'hmac_handler', undef,                      [  43 ,   43 ] ],
    'HS384' => [ 'hmac_handler', undef,                      [  64 ,   64 ] ],
    'HS512' => [ 'hmac_handler', undef,                      [  86 ,   86 ] ],
    'RS256' => [ 'rsa_handler', 'can_use_pkcs1_padding',     [ 171 ,  683 ] ],
    'RS384' => [ 'rsa_handler', 'can_use_pkcs1_padding',     [ 171 ,  683 ] ],
    'RS512' => [ 'rsa_handler', 'can_use_pkcs1_padding',     [ 171 ,  683 ] ],
    'PS256' => [ 'rsa_handler', 'can_use_pkcs1_pss_padding', [ 171 ,  683 ] ],
    'PS384' => [ 'rsa_handler', 'can_use_pkcs1_pss_padding', [ 171 ,  683 ] ],
    'PS512' => [ 'rsa_handler', 'can_use_pkcs1_pss_padding', [ 171 ,  683 ] ],
    'ES256' => [ 'ecc_handler',  undef,                      [  86 ,   86 ] ],
    'ES384' => [ 'ecc_handler',  undef,                      [ 128 ,  128 ] ],
    'ES512' => [ 'ecc_handler',  undef,                      [ 176 ,  176 ] ],
};

has 'hmac_handler' => ( is => 'lazy');
has 'rsa_handler'  => ( is => 'lazy');
has 'ecc_handler'  => ( is => 'lazy');
has 'last_error'   => ( is => 'rwp', default => '' );
has 'throw_errors' => ( is => 'rw',  default => 0  );

sub encode {
    my($self, $params ) = parse_params(@_);
    $self->_set_last_error('');
    unless(defined($params->{'secret'})
           && ( length($params->{'secret'}) >= 32
               || ref($params->{'secret'}) eq 'HASH')
          ){
        $self->_set_last_error('Missing or invalid secret for signing');
        croak($self->last_error) if $self->throw_errors;
        return undef;
    }
    my $header = $params->{'header'};
    unless($header && ref($header) eq 'HASH') {
        $self->_set_last_error('Missing or invalid header argument');
        croak($self->last_error) if $self->throw_errors;
        return undef;
    }
    
    my $input_alg = uc($header->{alg} || 'MISSING');
    
    my $handler = $self->_supported_algorithm($input_alg);
    
    unless( $handler ) {
        $self->_set_last_error(qq(Algorithm "$input_alg" is not supported));
        croak($self->last_error) if $self->throw_errors;
        return undef;
    }
    
    my $claims = $params->{claims};
    unless($claims && ref($claims) eq 'HASH' && scalar( keys %$claims  ) ) {
        $self->_set_last_error('Missing or invalid claims argument');
        croak($self->last_error) if $self->throw_errors;
        return undef;
    }
           
    $header->{alg} = $input_alg;
    $header->{typ} ||= 'JWT';
    
    my $d_flag = ( $params->{non_deterministic} ) ? 1 : 0;
    
    my $header_segment  = $self->encode_jwt_segment($header);
    my $claims_segment  = $self->encode_jwt_segment($claims);
    my $signature_input = join '.', $header_segment, $claims_segment;
    my $signature = try {
        $self->$handler->sign(
            {
                algorithm         => $input_alg,
                message           => $signature_input,
                key               => $params->{'secret'},
                non_deterministic => $d_flag
            }
        );
    } catch {
        my $error = $self->_clean_handler_error( $_ );
        $self->_set_last_error('Error signing token : ' . $error);
        croak($self->last_error) if $self->throw_errors;
        return undef;
    };
    
    if (defined($signature)) {
        return join '.', $signature_input, $self->encode_jwt_signature($signature);
    } else {
        return undef;
    }
}

sub decode_unverified {
    my($self, $params) = parse_params(@_);
    
    $self->_set_last_error('');
    
    my $return = {
        header      => undef,
        claims      => undef,
        verifytoken => undef,
    };
    unless($params->{token}) {
        my $errstring = 'Missing token argument';
        $self->_set_last_error($errstring);
        croak($self->last_error) if $self->throw_errors;
        return undef;
    }
    
    my $segments = [ split '\.', $params->{token} ];
    {
        my $segcount = @$segments;
        unless($segcount == 3) {
            my $errstring = "Invalid number of segments( $segcount ) in token";
            $self->_set_last_error($errstring);
            croak($self->last_error) if $self->throw_errors;
            return undef;
        }
    }
    
    my ($header_segment, $claims_segment, $crypto_segment) = @$segments;
    my ($header, $claims);
    my $caughterror = try {
        $header   = $self->decode_jwt_segment($header_segment);
        $claims   = $self->decode_jwt_segment($claims_segment);
        return 0;
    } catch {
        my $errstring = 'Error decoding token : ' . $self->_clean_handler_error( $_ );
        $self->_set_last_error($errstring);
        croak($self->last_error) if $self->throw_errors;
        return 1;
    };
    
    return undef if $caughterror;
    
    $return->{claims} = $claims;
    $return->{header} = $header;
    
    my $algo = 'NONE';
    
    if ( ref($header) eq 'HASH' && exists($header->{alg}) ) {
        $algo = uc($header->{alg} || 'NONE' );
    }
    
    my $signature_input = join('.', $header_segment, $claims_segment );
    
    my $verifytoken = join(':', $algo, $signature_input, $crypto_segment );
    $return->{verifytoken} = $verifytoken;
    return $return;
}

sub verify {
    my($self, $params) = parse_params(@_);
    
    $self->_set_last_error('');
    
    unless(defined($params->{'secret'})
           && ( length($params->{'secret'}) >= 32
               || ref($params->{'secret'}) eq 'HASH')
          ){
        $self->_set_last_error('Missing or invalid secret for signing');
        croak($self->last_error) if $self->throw_errors;
        return undef;
    }
    
    unless($params->{verifytoken}) {
        $self->_set_last_error('No verifytoken provided');
        croak($self->last_error) if $self->throw_errors;
        return undef;
    }
        
    my $segments = [ split ':', $params->{verifytoken} ];
    
    {
        my $segcount = @$segments;
        unless($segcount == 3) {
            $self->_set_last_error("Invalid number of segments($segcount) in verifytoken");
            croak($self->last_error) if $self->throw_errors;
            return undef;
        }
    }
    
    my( $input_algorithm, $signature_input, $crypto_segment ) = @$segments;
    
    my ( $signature );
    try {
        $signature = $self->decode_jwt_signature($crypto_segment);
    } catch {
        my $error = $self->_clean_handler_error( $_ );
        $self->_set_last_error("Invalid verifytoken");
        croak($self->last_error) if $self->throw_errors;
        return undef
    };
        
    my $handler = $self->_supported_algorithm($input_algorithm);
            
    unless( $handler ) {
        $self->_set_last_error(qq(header algorithm "$input_algorithm" is not supported));
        croak($self->last_error) if $self->throw_errors;
        return undef;
    }
    
    my $verified = try {
        $self->$handler->verify({
            algorithm => $input_algorithm,
            message   => $signature_input,
            key       => $params->{secret},
            signature => $signature
        });
    } catch {
        my $error = $self->_clean_handler_error( $_ );
        $self->_set_last_error('Error verifying token : ' . $error);
        croak($self->last_error) if $self->throw_errors;
        return undef;
    };
    
    return ( $verified && $verified eq '1' ) ? 1 : 0;
}

sub can_use_pkcs1_padding {
    return shift->rsa_handler->can_use_pkcs1_padding;
}

sub can_use_pkcs1_pss_padding {
    return shift->rsa_handler->can_use_pkcs1_pss_padding;
}

sub can_do_non_deterministic {
    return shift->ecc_handler->can_do_non_deterministic;
}

sub can_do_deterministic {
    return shift->ecc_handler->can_do_deterministic;
}

sub _supported_algorithm {
    my($self, $algo) = @_;
    return undef unless( $algo );
    if ( exists($ALGO_MAP->{$algo}) ) {
        my $handler = $ALGO_MAP->{$algo}->[0];
        my $check   = $ALGO_MAP->{$algo}->[1];
        if ( $check ) {
            return ( $self->$handler->$check ) ? $handler : undef; 
        } else {
            return $handler;
        }
    } else {
        return undef;
    }
}

sub _valid_signature_length {
    my($self, $algo, $length) = @_;
    return 0 unless($algo && $length && $length =~ m!^[1-9][0-9]{1,3}$!);
    if (exists($ALGO_MAP->{$algo})) {
        my( $min, $max ) = @{ $ALGO_MAP->{$algo}->[2] };
        return ( $length >= $min && $length <= $max ) ? 1 : 0;
    }
    return 0;
}

sub _clean_handler_error {
    my( $self, $error ) = @_;
    $error ||= 'unknown error';
    my ($clean_error) = $error =~ m!^([\x00-\x7F]*)!;
    $clean_error ||= 'unknown error';
    my ($report_error) = split(/[\n\r]+/, $clean_error);
    $report_error =~ s! at .+ line [0-9]+\.$!!;
    return $report_error;
}

sub _build_hmac_handler {
    return Crypt::JWS::OpenSSL::Algorithm::HMAC->new;
}

sub _build_rsa_handler {
    return Crypt::JWS::OpenSSL::Algorithm::RSA->new;
}

sub _build_ecc_handler {
    return Crypt::JWS::OpenSSL::Algorithm::ECC->new;
}

# ABSTRACT: Encode, decode and verify signed compact JWTs using OpenSSL modules

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL - Encode, decode and verify signed compact JWTs using OpenSSL modules

=head1 VERSION

version 0.005

=head1 SYNOPSYS

  use Crypt::JWS::OpenSSL;
  my $cjos = Crypt::JWS::OpenSSL->new;
  
  my $token = $cjos->encode(
      header => $header_ref,
      claims => $claims_ref,
      secret => $key,
  );
  
  if(!$token) {
     $logger->log_error( $cjos->last_error)
  }
  
  ###################
  ## in some module
  ###################
  
  use Crypt::JWS::OpenSSL;
  
  has verifier => ( is => 'ro', default => sub { Crypt::JWS::OpenSSL->new } );
  
  sub permissions_from_token {
    my($self, $token) = @_;
    my $unverified = $self->verifier->decode_unverified(token => $token);
    unless($unverified) {
        my $reason = $self->verifier->last_error;
        ## inspect and log reason
        return undef;
    }
    my ($secret, $permissions) = $self->examine_token(
        $unverified->{header}, $unverified->{claims}
    );
    unless($secret && $permissions) {
      ## no secret and permissions
      return undef;
    }
    my $ok = $self->verifier->verify(
      secret      => $secret,
      verifytoken => $unverified->{verifytoken}
    );
    unless( $ok && $ok eq '1' ) {
       my $reason = $self->verifier->last_error;
       ## inspect and log reason
       return undef;
    }
    ## log access
    ## grant permissions
    return $permissions;
  }

=head1 DESCRIPTION

Encode, decode and verify signed compact JWTs using Crypt::OpenSSL modules.

=head1 SUPPORTED ALGORITHMS

=head2 Shared HMAC secret

HS256 HS384 HS512

These algorithms do not require any Crypt::OpenSSL modules. They are included for completeness.

=head2 RSA

RS256 RS384 RS512 PS256 PS384 PS512

=head2 ECDSA

ES256 ES384 ES512

=head1 METHODS

=head2 encode

B<$cjo-E<gt>encode( header =E<gt> $header, claims =E<gt> $claims, secret =E<gt> $secret )>

Accepts a hash reference or an even numbered list.

Returns a signed compact JWT on success or undefined on error.

=head4 parameters

=over

=item header

A reference to a hash containing the header elements for the JWS.

At a minumim this must contain a B<alg> key/value with a value of
one of the L<supported algorithms|/SUPPORTED ALGORITHMS>.

If no B<typ> key/value is present, a default of B<typ =E<gt> 'JWT'> will be added.

=item claims

A reference to a hash containing the claim elements for the JWS.

This must contain at least 1 key/value pair.

=item secret

The secret used to sign the JWS.

For shared HMAC algorithms, this is a scalar containing the raw shared secret.

For RSA and ECDSA algorithms this can be a scalar containing the
full text of a pem encoded private key.

A reference to a hash containing the elements of a JWK can also be used.

For a regularly used private key it is more efficient to store the key
as pem encoded text. You can convert a JWK using L<Crypt::JWS::OpenSSL::Util::JWK>.

Where a B<kid> is required by a verifying recipient, it must always be added to
the header hash. It will not be taken from the value within a JWK.

=back

For errors and exceptions see L<error handling|/ERROR HANDLING>

=head2 decode_unverified

B<$cjo-E<gt>decode_unverified( token =E<gt> $tokenreceived )>

Accepts a hash reference or an even numbered list.

On success, returns the decocoded header and claims hash references
together with a 'verifytoken' that can be passed to L</verify>.

Returns undefined on error.

=head4 parameters

=over

=item token

A token to decode.

=back

Returned hash reference structure

  {
    header      => { ... },
    claims      => { ... },
    verifytoken => 'xxxxxxxxxxxx....'
  }

After inspecting the header and claims, the appropriate secret can
be passed to L</verify> to verify the signature.

For errors and exceptions see L<error handling|/ERROR HANDLING>

=head2 verify

B<$cjo-E<gt>verify( verifytoken =E<gt> $verifytoken, secret =E<gt> $secret )>

Accepts a hash reference or an even numbered list.

On success returns 1. On failure or error returns 0 or undefined.

=head4 parameters

=over

=item verifytoken

The verifytoken member of the hash reference returned from a
prior call to L</decode_unverified>.

=item secret

The appropriate public key or shared HMAC secret determined by
inspection of the header and claims returned from a prior
call to L</decode_unverified>.

The secret for an RSA or ECDSA algorithm can be a scalar
containing the full text of a pem encoded public key.

A reference to a hash containing the elements of a JWK can also be used.

For a regularly used public key it is more efficient to store the key
as pem encoded text. You can convert a JWK using L<Crypt::JWS::OpenSSL::Util::JWK>.

=back
  
For errors and exceptions see L<error handling|/ERROR HANDLING>

=head1 PROPERTIES

=head2 last_error

Read only.

When any of the methods L</encode>, L</decode_unverified>,  L</verify> return
undefined or false, the reason is available in L</last_error>.

see L<error handling|/ERROR HANDLING>

see also L</throw_errors>

=head2 throw_errors

Read write.

Default value 0 (false)

While L</throw_errors> is false, errors or exceptions encountered in
L</encode>, L</decode_unverified> and L</verify> are caught and
stored in L</last_error> available to read when the method returns.

If throw_errors is set to 1 ( true ) the module croaks when errors and
exceptions are encountered in L</encode>, L</decode_unverified> and L</verify>.

see L<error handling|/ERROR HANDLING>

see also L</last_error>

=head2 can_use_pkcs1_padding

Read only.

Returns true ( 1 ) if Crypt::OpenSSL::RSA can 'use_pkcs1_padding'.

Returns false ( 0 ) if Crypt::OpenSSL::RSA cannot 'use_pkcs1_padding'.

This padding method is necessary for algorithms

RS256, RS384, and RS512

It is likely that your version of Crypt::OpenSSL::RSA supports
'use_pkcs1_padding' as only a couple of short lived versions did not.

=head2 can_use_pkcs1_pss_padding

Returns true ( 1 ) if Crypt::OpenSSL::RSA can 'use_pkcs1_pss_padding'.

Returns false ( 0 ) if Crypt::OpenSSL::RSA cannot 'use_pkcs1_pss_padding'.

This padding method is necessary for algorithms

PS256, PS384, and PS512

This padding method requires OpenSSL 3.x and Crypt::OpenSSL::RSA version
greater than or equal to 0.36

See also L<Crypt::JWS::OpenSSL::Local>

=head2 JSON

Read only. An instance of a JSON encoder / decoder

The default is JSON::MaybeXS->new->utf8(1);

If you have a partcular perference for a JSON module, 'use' that before 
Crypt::JWS::OpenSSL or provide your own instance.

  use JSON::XS;
  use Crypt::JWS::OpenSSL;
  
  ## OR
  
  use Crypt::JWS::OpenSSL;
  use JSON::XS;
  
  my $cjos = Crypt::JWS::OpenSSL->new( JSON => JSON::XS->new->utf8(1) );

=head1 ERROR HANDLING

When L</throw_errors> is 0 ( the default ) if errors or exceptions are encountered in
the methods L</encode>, L</decode_unverified> and L</verify>, the methods return
undefined or false and the reason is available in L</last_error>.

If L</throw_errors> is set to 1, the methods croak on errors or exceptions.

=head1 SEE ALSO

=head2 Crypt OpenSSL modules used

L<Crypt::OpenSSL::RSA>

L<Crypt::OpenSSL::EC>

L<Crypt::OpenSSL::ECDSA>

=head2 Alternatives for JWT handling.

L<CryptX> ( wraps the LibTomCrypt library )

L<Crypt::Perl> ( pure perl )

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
