package Crypt::JWS::OpenSSL::Algorithm::HMAC;
$Crypt::JWS::OpenSSL::Algorithm::HMAC::VERSION = '0.005';
use Moo;
with qw(
  Crypt::JWS::OpenSSL::Role::Algorithm
  Crypt::JWS::OpenSSL::Role::Encoder
);
use Digest::SHA;
use namespace::clean;

my $HMAC_ALGO_MAP = {
    HS256 => \&Digest::SHA::hmac_sha256,
    HS384 => \&Digest::SHA::hmac_sha384,
    HS512 => \&Digest::SHA::hmac_sha512,
};

sub sign {
    my( $self, $request) = parse_params(@_);
    my $algo = $request->{algorithm};
    my $method = $HMAC_ALGO_MAP->{$algo};
    return $method->($request->{message}, $request->{key});
}

sub verify {
    my( $self, $request) = parse_params(@_);
    my $algo = $request->{algorithm};
    my $method = $HMAC_ALGO_MAP->{$algo};
    my $checksig = $method->($request->{message}, $request->{key});
    return $checksig eq $request->{signature} ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL::Algorithm::HMAC - Sign and verify tokens using shared HMAC secrets

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Crypt::JWS::OpenSSL::Algorithm::HMAC;
  my $jws = Crypt::JWS::OpenSSL::Algorithm::HMAC->new;
  
  my $token = $jws->sign(
    algorithm => 'HS256',
    key       => $shared_secret,
    message   => join('.', $base64urlEncodedHeader, $base64urlEncodedClaims),
  );
    
  my $is_verified = $jws->verify(
    algorithm => 'HS256',
    key       => $shared_secret,
    message   => join('.', $base64urlEncodedHeader, $base64urlEncodedClaims),
    signature => $base64urlDecodedSignature,
  );

=head1 DESCRIPTION

This module uses Digest::SHA to produce HS256, HS384 and HS512 signatures.

It is included in L<Crypt::JWS::OpenSSL> to support these common JWT signing algorithms.

It is normally used by L<Crypt::JWS::OpenSSL#encode> and L<Crypt::JWS::OpenSSL#verify>
but it can be used directly if you handle the Base64 url encoding and decoding elswhere.

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

The shared secret.

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

The shared secret.

=item C<message>

The Base64 url encoded JSON header and the Base64 url encoded JSON claims joined together
with a '.' ( dot ) extracted from a token.

=item C<signature>

The Base64 url decoded raw signature extracted from the token.

=back

=head1 ALGORITHMS

=over

=item HS256

=item HS384

=item HS512

=back

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
