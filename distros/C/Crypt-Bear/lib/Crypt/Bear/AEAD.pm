package Crypt::Bear::AEAD;
$Crypt::Bear::AEAD::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: AEAD encoder baseclass BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::AEAD - AEAD encoder baseclass BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 $aead->reset($iv);
 $aead->aad_inject($aad);
 $aead->flip;
 my $ciphertext = $aead->run($plaintext, 1);
 my $tag = $aead->get_tag;

 $aead->reset($iv);
 $aead->aad_inject($aad);
 $aead->flip;
 my $decoded = $aead->run($ciphertext, 0);

=head1 DESCRIPTION

This is a base-class for Authenticated encryption with additional data, such as L<GCM|Crypt::Bear::GCM>, L<CCM|Crypt::Bear::CCM> and L<EAX|Crypt::Bear::EAX>. These are typtically used with a block cipher such as C<AES>.

=head1 METHODS

=head2 reset($nonce)

Start a new AEAD computation. The nonce value is provided as parameter to this function.

=head2 aad_inject($data)

Inject some additional authenticated data. Additional data may be provided in several chunks of arbitrary length.

=head2 flip()

This method MUST be called after injecting all additional authenticated data, and before beginning to encrypt the plaintext (or decrypt the ciphertext).

=head2 run($data, $encrypt)

Process some plaintext to encrypt (if C<$encrypt> is true)) or ciphertext to decrypt (if it is false), returning the result. Data may be provided in several chunks of arbitrary length.

=head2 get_tag()

Compute the authentication tag. All message data (encrypted or decrypted) must have been injected at that point. Also, this call may modify internal context elements, so it may be called only once for a given AEAD computation.

=head2 check_tag($tag)

An alternative to C<get_tag>, meant to be used by the receiver: the authentication tag is internally recomputed, and compared with the one provided as parameter.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
