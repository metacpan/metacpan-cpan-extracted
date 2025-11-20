package Crypt::HSM::Encrypt;
$Crypt::HSM::Encrypt::VERSION = '0.023';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 ongoing encryption operation.

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Encrypt - A PKCS11 ongoing encryption operation.

=head1 VERSION

version 0.023

=head1 SYNOPSIS

 my $stream = $session->open_encrypt('aes-gcm', $key, $iv);
 my $ciphertext;
 for my $chunk (@chunks) {
   $ciphertext .= $stream->add_data($chunk);
 }
 $ciphertext .= $stream->finish;

=head1 DESCRIPTION

This class represents an encrypting stream.

=head1 METHODS

=head2 add_data($plaintext)

This adds data to the encryption, and returns ciphertext.

=head2 finalize()

This finished the encryption, and returns and remaining ciphertext.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
