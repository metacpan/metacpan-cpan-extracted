package Crypt::Bear::RSA::PrivateKey;
$Crypt::Bear::RSA::PrivateKey::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: An RSA private key in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::RSA::PrivateKey - An RSA private key in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $plaintext = $private_key->oaep_decrypt('sha256', $data, '');

 my $signature = $private_key->pkcs1_sign('sha256', $hash);

=head1 DESCRIPTION

This represents an RSA public key.

=head1 METHODS

=head2 oaep_decrypt($digest, $ciphertext, $label)

This decrypts data encrypted by C<oaep_encrypt>. The C<$digest> and C<$label> must match the values used with the encrypt operation.

=head2 pkcs1_sign($digest, $hash)

This signs a hash, and returns the signature.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
