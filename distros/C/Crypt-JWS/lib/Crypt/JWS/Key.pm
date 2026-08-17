package Crypt::JWS::Key;

use 5.016;
use strict;
use warnings;

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Crypt::JWS::Key - keys for Crypt::JWS

=head1 SYNOPSIS

	my $key = Crypt::JWS::Key->from_pem($pem);        # private or public
	my $key = Crypt::JWS::Key->from_jwk(\%jwk);       # RSA / EC / oct
	my $key = Crypt::JWS::Key->from_secret($bytes);   # HS* shared secret
	my $key = Crypt::JWS::Key->generate('ES256');
	my $key = Crypt::JWS::Key->generate('RS256', bits => 3072);

	$key->to_pem;              # public SPKI PEM
	$key->to_pem(1);           # private PKCS8 PEM (croaks on public keys)
	$key->to_jwk;              # public JWK hashref
	$key->to_jwk(kid => ..., alg => 'ES256', use => 'sig');
	$key->thumbprint;          # RFC 7638, base64url
	$key->kty;                 # 'RSA' | 'EC' | 'oct'
	$key->is_private;

=head1 DESCRIPTION

A key handle over an OpenSSL EVP_PKEY (RSA, EC P-256/P-384/P-521) or a
raw shared secret (oct, for the HS* algorithms), implemented entirely
in XS. Import from PEM (PKCS8/traditional private, SPKI public) or JWK
parameters; export to PEM and public JWK; RFC 7638 thumbprints for kid
derivation.

Private JWK export is deliberately not implemented: private keys
persist as PEM (C<to_pem(1)>), and only public halves travel as JWKs.

=head1 METHODS

=head2 from_pem ($pem)

=head2 from_jwk (\%jwk)

=head2 from_secret ($bytes)

=head2 generate ($alg, %opts)

C<ES256/384/512> pick the matching curve; C<RS*> take C<< bits => >>
(default 2048, minimum 2048); C<HS*> mint a random secret of the digest
size.

=head2 to_pem ($private)

=head2 to_jwk (%opts)

Public JWK hashref; C<kid>, C<alg>, and C<use> pass through when given.

=head2 thumbprint / thumbprint_raw

=head2 kty / curve_bits / is_private

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
