package Crypt::Bear::RSA;
$Crypt::Bear::RSA::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: An RSA helper module in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::RSA - An RSA helper module in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my ($public, $private) = Crypt::Bear::RSA::generate_keypair($prng, 2048);

 my $ciphertext = $public_key->oaep_encrypt('sha256', $input, $prng, '');
 my $plaintext = $private_key->oaep_decrypt('sha256', $ciphertext, '');

 my $signature = $private_key->pkcs1_sign('sha256', $hash);
 if ($public_key->pkcs1_verify('sha256', $signature) eq $hash) {
     ...
 }

=head1 DESCRIPTION

RSA is supported by two classes, L<PublicKey|Crypt::Bear::RSA::PublicKey> and L<PrivateKey|Crypt::Bear::RSA::PrivateKey>, each implementing half of it.

=head1 METHODS

=head2 generate_keypair($prng, $size, $exponent = 0)

This uses the given L<PRNG|Crypt::Bear::PRNG> to generate a new pair of public and private RSA key of size C<$size>, and returns both. The C<$exponent> of the public key may be explicitly set, if not a sensible value will be picked automatically.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
