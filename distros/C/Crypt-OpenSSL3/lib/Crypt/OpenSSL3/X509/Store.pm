package Crypt::OpenSSL3::X509::Store;
$Crypt::OpenSSL3::X509::Store::VERSION = '0.009';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An X509 certificate store

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::Store - An X509 certificate store

=head1 VERSION

version 0.009

=head1 METHODS

=head2 new

=head2 add_cert

=head2 load_file

=head2 load_locations

=head2 load_path

=head2 load_store

=head2 lock

=head2 set_default_paths

=head2 set_depth

=head2 set_flags

=head2 set_purpose

=head2 set_trust

=head2 unlock

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
