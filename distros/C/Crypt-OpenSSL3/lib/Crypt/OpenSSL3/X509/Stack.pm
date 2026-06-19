package Crypt::OpenSSL3::X509::Stack;
$Crypt::OpenSSL3::X509::Stack::VERSION = '0.007';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A stack of X509 certificates

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::Stack - A stack of X509 certificates

=head1 VERSION

version 0.007

=head1 METHODS

=head2 new

=head2 delete

=head2 delete_ptr

=head2 find

=head2 find_all

=head2 find_ex

=head2 free

=head2 insert

=head2 is_sorted

=head2 num

=head2 pop

=head2 pop_free

=head2 push

=head2 reserve

=head2 set

=head2 shift

=head2 sort

=head2 unshift

=head2 value

=head2 zero

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
