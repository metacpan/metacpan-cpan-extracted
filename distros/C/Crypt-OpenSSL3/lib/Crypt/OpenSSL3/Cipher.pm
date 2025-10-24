package Crypt::OpenSSL3::Cipher;
$Crypt::OpenSSL3::Cipher::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: an abstraction around ciphers

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Cipher - an abstraction around ciphers

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $cipher = Crypt::OpenSSL3::Cipher->fetch('AES-128-GCM');
 my $context = Crypt::OpenSSL3::Cipher::Context->new;
 $context->init($cipher, $key, $iv, 1);
 my $ciphertext = $context->update($plaintext);
 $ciphertext .= $context->final;
 my $tag = $context->get_aead_tag(16);

 my $context2 = Crypt::OpenSSL3::Cipher::Context->new;
 $context2->init($cipher, $key, $iv, 0);
 my $decoded = $context2->update($ciphertext);
 $context2->set_aead_tag($tag);
 $decoded .= $context2->final // die "Invalid tag";

=head1 DESCRIPTION

This class holds a symmetric cipher. It's used to create a L<cipher context|Crypt::OpenSSL3::Cipher::Context> that will do the actual encryption/decryption.

=head1 METHODS

=head2 fetch

=head2 get_block_size

=head2 get_description

=head2 get_iv_length

=head2 get_key_length

=head2 get_mode

=head2 get_name

=head2 get_nid

=head2 get_param

=head2 get_type

=head2 is_a

=head2 list_all_provided

=head2 names_list_all

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
