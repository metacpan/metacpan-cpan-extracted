package Crypt::OpenSSL3::Cipher::Context;
$Crypt::OpenSSL3::Cipher::Context::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An instance of a symmetric encryption

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Cipher::Context - An instance of a symmetric encryption

=head1 VERSION

version 0.002

=head1 METHODS

=head2 new

=head2 init

=head2 copy

=head2 ctrl

=head2 dup

=head2 final

=head2 get_aead_tag

=head2 get_block_size

=head2 get_cipher

=head2 get_iv_length

=head2 get_key_length

=head2 get_mode

=head2 get_name

=head2 get_nid

=head2 get_param

=head2 is_encrypting

=head2 rand_key

=head2 reset

=head2 set_aead_ivlen

=head2 set_aead_tag

=head2 set_key_length

=head2 set_padding

=head2 set_params

=head2 type

=head2 update

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
