package Crypt::OpenSSL3::PKey;
$Crypt::OpenSSL3::PKey::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An assymetrical key

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::PKey - An assymetrical key

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $file = Crypt::OpenSSL3::BIO->new_file('priv.key', 'r');
 my $key = Crypt::OpenSSL3::Pkey->read_pem_private_key($file);

 my $ctx = Crypt::OpenSSL3::PKey::Context->new($key);
 $ctx->sign_init;
 my $signature = $ctx->sign($data);

=head1 DESCRIPTION

A PKey can be any kind of assymetrical key. This is a fat interface: no single key type supports all possible operations, and most operations aren't supported by all key types. At its core the operations are:

=over 4

=item * encrypt/decrypt

=item * sign/verify

=item * encapsulate/decapsulate

=item * derivation

=item * key generation

=item * parameter generation

=back

=head1 METHODS

=head2 new

=head2 new_raw_private_key

=head2 new_raw_public_key

=head2 read_pem_private_key

=head2 read_pem_public_key

=head2 write_pem_private_key

=head2 write_pem_public_key

=head2 can_sign

=head2 digestsign_supports_digest

=head2 dup

=head2 eq

=head2 get_base_id

=head2 get_bits

=head2 get_bn_param

=head2 get_default_digest_name

=head2 get_default_digest_nid

=head2 get_description

=head2 get_ec_point_conv_form

=head2 get_encoded_public_key

=head2 get_field_type

=head2 get_group_name

=head2 get_id

=head2 get_int_param

=head2 get_octet_string_param

=head2 get_param

=head2 get_raw_private_key

=head2 get_raw_public_key

=head2 get_security_bits

=head2 get_size

=head2 get_size_t_param

=head2 get_type_name

=head2 get_utf8_string_param

=head2 is_a

=head2 parameters_eq

=head2 print_params

=head2 print_private

=head2 print_public

=head2 set_bn_param

=head2 set_encoded_public_key

=head2 set_int_param

=head2 set_octet_string_param

=head2 set_params

=head2 set_size_t_param

=head2 set_type

=head2 set_type_str

=head2 set_utf8_string_param

=head2 type

=head2 type_names_list_all

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
