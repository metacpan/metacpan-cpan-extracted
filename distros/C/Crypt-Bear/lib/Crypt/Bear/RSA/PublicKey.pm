package Crypt::Bear::RSA::PublicKey;
$Crypt::Bear::RSA::PublicKey::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: An RSA public key in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::RSA::PublicKey - An RSA public key in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $ciphertext = $public_key->oaep_encrypt('sha256', $data, $prng, '');

 if ($public_key->pkcs1_verify('sha256', $signature) eq $hash) {
     ...
 }

=head1 DESCRIPTION

This represents an RSA public key.

=head1 METHODS

=head2 oaep_encrypt($digest, $plaintext, $prng, $label)

This encrypts the C<$plaintext>, using the given C<$digest>, C<$prng> and C<$label> (which may be an empty string).

=head2 pkcs1_verify($digest, $signature)

This verifies a signature, and returns the hash that was signed. It's the user's responsibility to check if that hash matches the expected value.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
