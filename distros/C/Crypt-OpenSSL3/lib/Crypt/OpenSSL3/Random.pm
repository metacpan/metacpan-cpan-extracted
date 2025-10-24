package Crypt::OpenSSL3::Random;
$Crypt::OpenSSL3::Random::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A kind of a random number generator

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Random - A kind of a random number generator

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $random_bytes = Crypt::OpenSSL3::Random->bytes(16);

=head1 METHODS

=head2 fetch

=head2 bytes

=head2 get_description

=head2 get_name

=head2 get_param

=head2 get_primary

=head2 get_private

=head2 get_public

=head2 is_a

=head2 list_all_provided

=head2 names_list_all

=head2 priv_bytes

=head2 set_private

=head2 set_public

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
