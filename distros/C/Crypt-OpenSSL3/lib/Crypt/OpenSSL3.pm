package Crypt::OpenSSL3;
$Crypt::OpenSSL3::VERSION = '0.002';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: A modern OpenSSL wrapper

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3 - A modern OpenSSL wrapper

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This distribution provides access to the SSL implementation and cryptography provided by OpenSSL. Key packages in this distribution include:

=over 4

=item * L<Crypt::OpenSSL3::SSL|Crypt::OpenSSL3::SSL> - actual SSL connections

=item * L<Crypt::OpenSSL3::PKey|Crypt::OpenSSL3::PKey> - Assymetrical keys

=item * L<Crypt::OpenSSL3::Cipher|Crypt::OpenSSL3::Cipher> - Symmetric ciphers

=item * L<Crypt::OpenSSL3::MD|Crypt::OpenSSL3::MD> - Message digests

=item * L<Crypt::OpenSSL3::MAC|Crypt::OpenSSL3::MAC> - Message Authentication Codes

=item * L<Crypt::OpenSSL3::KDF|Crypt::OpenSSL3::KDF> - Key Derivation Functions

=item * L<Crypt::OpenSSL3::X509|Crypt::OpenSSL3::X509> - X509 certificates

=back

This package itself only two pieces of functionality: error handling and build configuration introspection.

=head1 FUNCTIONS

=head2 clear_error

=head2 get_error

=head2 peek_error

=head2 info

=over 4

=item INFO_CONFIG_DIR

=item INFO_CPU_SETTINGS

=item INFO_DIR_FILENAME_SEPARATOR

=item INFO_DSO_EXTENSION

=item INFO_ENGINES_DIR

=item INFO_LIST_SEPARATOR

=item INFO_MODULES_DIR

=item INFO_WINDOWS_CONTEXT

=back

=head2 version

=over 4

=item BUILT_ON

=item CFLAGS

=item CPU_INFO

=item DIR

=item ENGINES_DIR

=item FULL_VERSION_STRING

=item MODULES_DIR

=item PLATFORM

=item VERSION_STRING

=item VERSION_TEXT

=item WINCTX

=back

=head2 version_build_metadata

=head2 version_major

=head2 version_minor

=head2 version_num

=head2 version_patch

=head2 version_pre_release

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
