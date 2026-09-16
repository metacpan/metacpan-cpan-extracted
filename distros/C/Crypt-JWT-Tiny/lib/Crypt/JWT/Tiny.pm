package Crypt::JWT::Tiny;
$Crypt::JWT::Tiny::VERSION = '0.002';
use 5.014;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/encode_jwt decode_jwt/;

use Carp;
use Digest::SHA qw/hmac_sha256 hmac_sha384 hmac_sha512/;
use JSON::PP;
use MIME::Base64 qw/encode_base64url decode_base64url/;

my $json = JSON::PP->new->utf8->canonical;

my %hmac_for = (
	HS256 => \&hmac_sha256,
	HS384 => \&hmac_sha384,
	HS512 => \&hmac_sha512,
);

my %length_for = (
	HS256 => 32,
	HS384 => 48,
	HS512 => 64,
);

sub encode_jwt {
	my %args = @_;
	my $claims  = $args{claims}   // croak "Missing claims";
	my $key     = $args{key}      // croak "Missing key";
	my $alg     = $args{alg}      // croak "Missing algorithm";
	my $hmac    = $hmac_for{$alg} // croak "Unknown algorithm $alg";
	croak 'Key too small' unless length $key >= $length_for{$alg};
	my $time    = $args{time}     // time;

	my %header  = (alg => $alg);
	$header{$_} = $args{$_} for grep defined $args{$_}, qw/typ kid/;

	my %claims = %{ $claims };
	$claims{iat} = $time if $args{auto_iat};
	$claims{exp} //= $time + $args{relative_exp} if defined $args{relative_exp};
	$claims{nbf} //= $time + $args{relative_nbf} if defined $args{relative_nbf};

	my $header        = $json->encode(\%header);
	my $body          = $json->encode(\%claims);
	my $signing_input = join '.', map { encode_base64url($_) } $header, $body;
	my $signature     = $hmac->($signing_input, $key);

	return $signing_input . '.' . encode_base64url($signature);
}

sub _secure_compare {
	my ($up, $down) = @_;
	my $r     = length $up != length $down;
	my $left  = $up . $down;
	my $right = $down . $up;
	$r |= ord(substr $left, $_, 1) ^ ord(substr $right, $_, 1) for 0 .. length($left) - 1;
	return $r == 0;
}

sub _valid_number {
	my ($value) = @_;
	return defined $value && !ref $value && $value =~ / \A \d+ (?: \.\d+)? \z /xa;
}

sub _valid_string {
	my ($value) = @_;
	return defined $value && !ref $value && length $value;
}

sub _to_media_type {
	my ($type) = @_;
	$type =~ s{^([^/]+)(?=;|$)}{application/$1};
	$type =~ s/^([^;]+)(?=;|$)/\L$1/;
	return $type;
}

my $base64 = qr/[A-Za-z0-9_-]+/;

sub decode_jwt {
	my %args    = @_;
	my $token   = $args{token}  // croak 'Missing token';
	my $key_arg = $args{key}    // croak 'Missing key';
	my $alg     = $args{alg}    // croak 'Missing algorithm';
	my $time    = $args{time}   // time;
	my $leeway  = $args{leeway} // 0;

	my ($header_str, $body, $signature) = $token =~ / \A ($base64) \. ($base64) \. ($base64) \z /x or croak 'Could not parse token';
	my $header = eval { $json->decode(decode_base64url($header_str)) } or croak 'Invalid header';
	croak "Header is not a hash" if ref $header ne 'HASH';
	croak 'Unsupported crit header' if exists $header->{crit};

	my @algs = ref $alg eq 'ARRAY' ? @{$alg} : $alg;
	croak 'Missing or invalid alg header' if not _valid_string($header->{alg});
	croak "Algorithm '$header->{alg}' is not allowed" unless grep { $header->{alg} eq $_ } @algs;
	my $hmac = $hmac_for{ $header->{alg} } // croak "Unknown algorithm '$header->{alg}'";
	my $decoded_signature = decode_base64url($signature);
	croak "Signature has incorrect length" if length $decoded_signature != $length_for{ $header->{alg} };

	my $key           = ref $key_arg eq 'CODE' ? $key_arg->(%{ $header }) : $key_arg;
	croak 'Invalid key' unless _valid_string($key);
	my $signing_input = join '.', $header_str, $body;
	my $computed = $hmac->($signing_input, $key);
	croak 'Incorrect MAC' unless _secure_compare($computed, $decoded_signature);

	if (defined $args{typ}) {
		my $type = $header->{typ} // croak "No type given";
		croak 'Incorrect type' if _to_media_type($type) ne _to_media_type($args{typ});
	}
	croak 'Nested types are not supported' if defined $header->{cty};

	my $result = eval { $json->decode(decode_base64url($body)) } or croak 'Invalid payload';
	croak 'Payload is not a hash' if ref $result ne 'HASH';

	if (defined $result->{exp}) {
		croak 'Invalid expiration' unless _valid_number($result->{exp});
		croak 'Token is expired' if $time > $result->{exp} + $leeway;
	}
	if (defined $result->{nbf}) {
		croak 'Invalid not-before' unless _valid_number($result->{nbf});
		croak 'Token is not yet valid' if $time < $result->{nbf} - $leeway;
	}
	if (defined $args{max_age}) {
		croak 'Invalid creation time' unless _valid_number($result->{iat});
		croak 'Token is too old' if $time > $result->{iat} + $args{max_age} + $leeway;
	}

	croak 'Incorrect issuer' if defined $args{iss} and (not _valid_string($result->{iss}) or $result->{iss} ne $args{iss});
	if (defined $args{aud}) {
		croak 'No audience present' unless defined $result->{aud};
		my @aud = ref $result->{aud} eq 'ARRAY' ? @{ $result->{aud} } : $result->{aud};
		croak 'Incorrect audience' unless grep { _valid_string($_) and $_ eq $args{aud} } @aud;
	}

	return $result;
}

1;

# ABSTRACT: A small HMAC-only JWT implementation

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWT::Tiny - A small HMAC-only JWT implementation

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 # encoding
 use Crypt::JWT::Tiny 'encode_jwt';
 my $jws_token = encode_jwt(claims => $data, alg => 'HS256', key => $secret);

 # decoding
 use Crypt::JWT::Tiny 'decode_jwt';
 my $claims = decode_jwt(token => $jws_token, alg => 'HS256', key => $secret);

=head1 DESCRIPTION

This is a tiny JWT implementation. It only depends on core modules, and as such can only support the HMAC algorithms (C<HS256>, C<HS384> and C<HS512>). If you need more than that, I recommend looking for a more complete implementation of JWT.

=head1 FUNCTIONS

=head2 encode_jwt

Returns the encoded JWT as a string using the compact serialization format. Croaks on bad arguments or unsupported algorithm. It takes the following named arguments

=over 4

=item claims

Mandatory. It takes a hash ref of claims that will be JSON serialized.

 my %claims = (iss => 'me', aud => 'you', sub => 'him');
 my $token = encode_jwt(claims => \%claims, key => $k, alg => 'HS256');

=item alg

Mandatory. The algorithm used to sign the token. Three values are currently supported:

=over 4

=item * C<HS256>

HMAC using SHA-256

=item * C<HS384>

HMAC using SHA-384

=item * C<HS512>

HMAC using SHA-512

=back

=item key

Mandatory. The secret key used to sign the token. This must be a binary string. It is required to be at least as long as the hash output (e.g. 32 bytes for SHA-256).

=item kid

The key identifier. If any is given this will be added to the token's header.

=item typ

The type of the token. If any is given (typically C<JWT>), it will be added to the token's header.

=item relative_exp

Set the C<exp> (Expiration Time) claim to C<current time + relative_exp> value (in seconds). This will not overwrite an existing value.

It is highly recommended to either add an C<exp> expiration time using C<relative_exp> or add an C<iat> and check with C<max_age>.

=item relative_nbf

Set the C<nbf> (Not Before) claim to C<current time + relative_nbf> value (in seconds). This will not overwrite an existing value.

=item auto_iat

This will automatically add an iat (creation time) value to the claims. This will overwrite an existing value.

=back

=head2 decode_jwt

This decodes a C<JWT> to a hashref of claims, or croaks when any error is encountered.

It will automatically verify C<exp> and C<nbf>, and on request also C<iss>, C<aud>, C<typ> and C<iat>.

=over 4

=item token

Mandatory. The token to be decoded.

=item alg

Mandatory. The algorithm used to verify the token. This is either a string, or a array ref of strings.

=item key

Mandatory. The secret key used to verify the token. This must either be a binary string, or a function reference to a function that is passed the (decoded) headers as a hash and must return the appropriate key. One should note that the input values should be treated as coming from an untrusted source.

=item iss

This will check if the passed issuer equals the received issuer.

=item aud

This will check if passed audience is listed among the received audiences.

=item typ

The type of the token. If any is given (typically C<JWT>, or C<at+jwt> for access tokens), it must match the value in the token. It is matched case-insensitively.

=item max_age

If given, the token must contain an iat claim and be no older than this many seconds (plus leeway).

=item leeway

Number of seconds of clock skew to tolerate when checking timestamps. Defaults to C<0>.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
