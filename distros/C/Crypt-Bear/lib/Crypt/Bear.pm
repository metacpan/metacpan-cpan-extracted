package Crypt::Bear;
$Crypt::Bear::VERSION = '0.003';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: BearSSL for Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear - BearSSL for Perl

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This distribution provides a Perl wrapper for the BearSSL library. First and foremost it provides an SSL implementation, but it also provides access to various primitives such as symmetric and asymmetric encryption, hashes, CSPRNGs and basic certificate handling.

=head1 METHODS

=head2 get_config()

This method returns a hash with the configuration arguments of this BearSSL.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
