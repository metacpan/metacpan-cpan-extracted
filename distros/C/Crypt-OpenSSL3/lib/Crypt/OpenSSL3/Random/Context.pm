package Crypt::OpenSSL3::Random::Context;
$Crypt::OpenSSL3::Random::Context::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A instance of a random number generator

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Random::Context - A instance of a random number generator

=head1 VERSION

version 0.002

=head1 METHODS

=head2 enable_locking

=head2 generate

=head2 get_rand

=head2 get_state

=head2 get_strength

=head2 instantiate

=head2 new

=head2 nonce

=head2 reseed

=head2 uninstantiate

=head2 verify_zeroization

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
