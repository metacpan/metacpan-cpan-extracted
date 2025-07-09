package Crypt::Bear::EC::PublicKey;
$Crypt::Bear::EC::PublicKey::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: An EC public key in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::EC::PublicKey - An EC public key in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 if ($public_key->ecdsa_verify('sha256', $hash, $signature)) {
     say "Success!";
 }

 my $shared = $private_key->ecdh_key_exchange($public_key);

=head1 DESCRIPTION

This represents a elliptic curve public key. The curve type can be one of the following:

=over 4

=item * C<'sect163k1'>

=item * C<'sect163r1'>

=item * C<'sect163r2'>

=item * C<'sect193r1'>

=item * C<'sect193r2'>

=item * C<'sect233k1'>

=item * C<'sect233r1'>

=item * C<'sect239k1'>

=item * C<'sect283k1'>

=item * C<'sect283r1'>

=item * C<'sect409k1'>

=item * C<'sect409r1'>

=item * C<'sect571k1'>

=item * C<'sect571r1'>

=item * C<'secp160k1'>

=item * C<'secp160r1'>

=item * C<'secp160r2'>

=item * C<'secp192k1'>

=item * C<'secp192r1'>

=item * C<'secp224k1'>

=item * C<'secp224r1'>

=item * C<'secp256k1'>

=item * C<'secp256r1'>

=item * C<'secp384r1'>

=item * C<'secp521r1'>

=item * C<'brainpoolP256r1'>

=item * C<'brainpoolP384r1'>

=item * C<'brainpoolP512r1'>

=item * C<'curve25519'>

=item * C<'curve448'>

=back

Common values include C<'curve25519'>, C<'curve448'>, C<'secp256r1'>, C<'secp384r1'>, C<'secp521r1'>.

=head1 METHODS

=head2 new($curve, $point)

This returns a new public key representing the given C<$point> on C<$curve>.

=head2 ecdsa_verify($hash_type, $hash_value, $signature)

This verifies a C<$signature> as returned by C<ecdsa_sign>. The C<$hash_value> must be the hash you computer yourself over the data.

=head2 curve()

This returns the curve of this public key.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
