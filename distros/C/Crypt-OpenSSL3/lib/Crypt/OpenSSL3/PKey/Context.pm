package Crypt::OpenSSL3::PKey::Context;
$Crypt::OpenSSL3::PKey::Context::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An operation using a PKey

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::PKey::Context - An operation using a PKey

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $ctx = Crypt::OpenSSL3::PKey::Context->new_from_name('RSA');
 $ctx->keygen_init;
 $ctx->set_params({ bits => 2048, primes => 2, e => 65537 });
 my $pkey = $ctx->generate;

=head1 METHODS

=head2 new

=head2 new_from_name

=head2 new_from_pkey

=head2 new_id

=head2 add_hkdf_info

=head2 auth_decapsulate_init

=head2 auth_encapsulate_init

=head2 decapsulate

=head2 decapsulate_init

=head2 decrypt

=head2 decrypt_init

=head2 derive

=head2 derive_init

=head2 derive_set_peer

=head2 dup

=head2 encapsulate

=head2 encapsulate_init

=head2 encrypt

=head2 encrypt_init

=head2 generate

=head2 get_dh_kdf_md

=head2 get_dh_kdf_oid

=head2 get_dh_kdf_outlen

=head2 get_dh_kdf_type

=head2 get_ecdh_cofactor_mode

=head2 get_ecdh_kdf_md

=head2 get_ecdh_kdf_outlen

=head2 get_ecdh_kdf_type

=head2 get_group_name

=head2 get_id

=head2 get_keygen_info

=head2 get_param

=head2 get_rsa_mgf1_md

=head2 get_rsa_mgf1_md_name

=head2 get_rsa_oaep_label

=head2 get_rsa_oaep_md

=head2 get_rsa_oaep_md_name

=head2 get_rsa_padding

=head2 get_rsa_pss_saltlen

=head2 get_signature_md

=head2 is_a

=head2 keygen_init

=head2 paramgen_init

=head2 set_dh_kdf_md

=head2 set_dh_kdf_oid

=head2 set_dh_kdf_outlen

=head2 set_dh_kdf_type

=head2 set_dh_nid

=head2 set_dh_pad

=head2 set_dh_paramgen_generator

=head2 set_dh_paramgen_gindex

=head2 set_dh_paramgen_prime_len

=head2 set_dh_paramgen_seed

=head2 set_dh_paramgen_subprime_len

=head2 set_dh_paramgen_type

=head2 set_dh_rfc5114

=head2 set_dhx_rfc5114

=head2 set_dsa_paramgen_bits

=head2 set_dsa_paramgen_gindex

=head2 set_dsa_paramgen_md

=head2 set_dsa_paramgen_md_props

=head2 set_dsa_paramgen_q_bits

=head2 set_dsa_paramgen_seed

=head2 set_dsa_paramgen_type

=head2 set_ec_param_enc

=head2 set_ec_paramgen_curve_nid

=head2 set_ecdh_cofactor_mode

=head2 set_ecdh_kdf_md

=head2 set_ecdh_kdf_outlen

=head2 set_ecdh_kdf_type

=head2 set_group_name

=head2 set_hkdf_key

=head2 set_hkdf_md

=head2 set_hkdf_mode

=head2 set_hkdf_salt

=head2 set_id

=head2 set_kem_op

=head2 set_mac_key

=head2 set_params

=head2 set_rsa_keygen_bits

=head2 set_rsa_keygen_primes

=head2 set_rsa_mgf1_md

=head2 set_rsa_mgf1_md_name

=head2 set_rsa_oaep_label

=head2 set_rsa_oaep_md

=head2 set_rsa_oaep_md_name

=head2 set_rsa_padding

=head2 set_rsa_pss_saltlen

=head2 set_signature

=head2 set_signature_md

=head2 sign

=head2 sign_init

=head2 sign_message_final

=head2 sign_message_init

=head2 sign_message_update

=head2 verify

=head2 verify_init

=head2 verify_message_final

=head2 verify_message_init

=head2 verify_message_update

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
