package Crypt::OpenSSL3::Timestamp::TokenInfo;
$Crypt::OpenSSL3::Timestamp::TokenInfo::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A Timestamp Protocol token information object

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Timestamp::TokenInfo - A Timestamp Protocol token information object

=head1 VERSION

version 0.010

=head1 METHODS

=head2 new

=head2 add_ext

=head2 decode_der

=head2 delete_ext

=head2 encode_der

=head2 get_accuracy

=head2 get_ext

=head2 get_ext_by_NID

=head2 get_ext_by_OBJ

=head2 get_ext_by_critical

=head2 get_ext_count

=head2 get_msg_imprint

=head2 get_nonce

=head2 get_ordering

=head2 get_policy_id

=head2 get_serial

=head2 get_time

=head2 get_tsa

=head2 get_version

=head2 print

=head2 read_der

=head2 set_accuracy

=head2 set_msg_imprint

=head2 set_nonce

=head2 set_ordering

=head2 set_policy_id

=head2 set_serial

=head2 set_time

=head2 set_tsa

=head2 set_version

=head2 write_der

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
