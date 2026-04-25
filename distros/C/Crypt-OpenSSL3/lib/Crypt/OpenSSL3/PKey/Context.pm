package Crypt::OpenSSL3::PKey::Context;
$Crypt::OpenSSL3::PKey::Context::VERSION = '0.005';
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

version 0.005

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

=head2 get_param

=head2 is_a

=head2 keygen_init

=head2 paramgen_init

=head2 set_params

=head2 set_signature

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
