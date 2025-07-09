package Crypt::Bear::CTR;
$Crypt::Bear::CTR::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: CTR encoder baseclass BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::CTR - CTR encoder baseclass BearSSL

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This base class represents an CTR implementation, currently it's only implementation is L<Crypt::Bear::AES_CTR>.

=head1 METHODS

=head2 run($iv, $data)

This runs a CTR encode/decode with the given IV and data, and returns the result.

The `iv` parameter' length must be exactly 4 bytes less than the block size (e.g. 12 bytes for AES/CTR). The IV is combined with a 32-bit block counter to produce the block value which is processed with the block cipher.

The data's length is not required to be a multiple of the block size; if the final block is partial, then the corresponding key stream bits are dropped.

=head2 block_size()

This returns the blocksize of the cipher.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
