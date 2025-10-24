package Crypt::OpenSSL3::BIO;
$Crypt::OpenSSL3::BIO::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An OpenSSL IO instance

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::BIO - An OpenSSL IO instance

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $bio = Crypt::OpenSSL3::BIO->new_file('filename', 'r');

 my ($left, $right) = Crypt::OpenSSL3::BIO->new_bio_pair;

=head1 DESCRIPTION

A BIO is a OpenSSL IO handle. It is needed for an L<SSL|Crypt::OpenSSL3::SSL> connection, and to read/write various file formats.

=head1 METHODS

=head2 new_bio_pair

=head2 new_dgram

=head2 new_fd

=head2 new_file

=head2 new_mem

=head2 new_socket

=head2 ctrl_pending

=head2 ctrl_wpending

=head2 eof

=head2 flush

=head2 get_close

=head2 get_ktls_recv

=head2 get_ktls_send

=head2 get_line

=head2 get_rpoll_descriptor

=head2 get_wpoll_descriptor

=head2 gets

=head2 pending

=head2 puts

=head2 read

=head2 reset

=head2 seek

=head2 set_close

=head2 tell

=head2 wpending

=head2 write

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
