package Crypt::OpenSSL3::BIO::Address;
$Crypt::OpenSSL3::BIO::Address::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A network address for BIO objects

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::BIO::Address - A network address for BIO objects

=head1 VERSION

version 0.010

=head1 METHODS

=head2 new

=head2 dup

=head2 clear

=head2 copy

=head2 family

=head2 hostname_string

=head2 path_string

=head2 rawaddress

=head2 rawmake

=head2 rawport

=head2 service_string

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
