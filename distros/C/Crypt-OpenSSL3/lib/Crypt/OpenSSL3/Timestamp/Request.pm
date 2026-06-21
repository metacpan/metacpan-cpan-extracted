package Crypt::OpenSSL3::Timestamp::Request;
$Crypt::OpenSSL3::Timestamp::Request::VERSION = '0.008';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A Timestamp Protocol request

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Timestamp::Request - A Timestamp Protocol request

=head1 VERSION

version 0.008

=head1 METHODS

=head2 new

=head2 add_ext

=head2 delete_ext

=head2 get_cert_req

=head2 get_ext

=head2 get_ext_by_NID

=head2 get_ext_by_OBJ

=head2 get_ext_by_critical

=head2 get_ext_count

=head2 get_msg_imprint

=head2 get_nonce

=head2 get_policy_id

=head2 get_version

=head2 print

=head2 read_der

=head2 set_cert_req

=head2 set_msg_imprint

=head2 set_nonce

=head2 set_policy_id

=head2 set_version

=head2 write_der

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
