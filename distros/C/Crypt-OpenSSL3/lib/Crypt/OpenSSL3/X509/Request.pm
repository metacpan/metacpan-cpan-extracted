package Crypt::OpenSSL3::X509::Request;
$Crypt::OpenSSL3::X509::Request::VERSION = '0.006';
use strict;
use warnings;

1;

# ABSTRACT: A X509 / PKCS10 certificate signing request

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::Request - A X509 / PKCS10 certificate signing request

=head1 VERSION

version 0.006

=head1 METHODS

=head2 add_attr

=head2 add_attr_by_NID

=head2 add_attr_by_OBJ

=head2 add_attr_by_txt

=head2 check_private_key

=head2 delete_attr

=head2 digest

=head2 dup

=head2 get_X509_pubkey

=head2 get_attr

=head2 get_attr_by_NID

=head2 get_attr_by_OBJ

=head2 get_attr_count

=head2 get_distinguishing_id

=head2 get_pubkey

=head2 get_signature

=head2 get_signature_nid

=head2 get_subject_name

=head2 get_version

=head2 new

=head2 set_distinguishing_id

=head2 set_pubkey

=head2 set_signature

=head2 set_signature_algo

=head2 set_subject_name

=head2 set_version

=head2 sign

=head2 sign_ctx

=head2 verify

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
