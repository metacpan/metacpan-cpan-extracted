package Crypt::OpenSSL3::KDF::Context;
$Crypt::OpenSSL3::KDF::Context::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A KDF instance

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::KDF::Context - A KDF instance

=head1 VERSION

version 0.002

=head1 METHODS

=head2 new

=head2 derive

=head2 dup

=head2 get_kdf_size

=head2 get_param

=head2 kdf

=head2 reset

=head2 set_params

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
