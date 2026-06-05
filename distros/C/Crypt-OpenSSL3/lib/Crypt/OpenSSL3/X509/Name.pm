package Crypt::OpenSSL3::X509::Name;
$Crypt::OpenSSL3::X509::Name::VERSION = '0.006';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A name in a X509 certificate

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::Name - A name in a X509 certificate

=head1 VERSION

version 0.006

=head1 METHODS

=head2 add_entry

=head2 add_entry_by_NID

=head2 add_entry_by_OBJ

=head2 add_entry_by_txt

=head2 cmp

=head2 delete_entry

=head2 digest

=head2 dup

=head2 entry_count

=head2 get_entry

=head2 get_index_by_NID

=head2 get_index_by_OBJ

=head2 hash

=head2 oneline

=head2 print

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
