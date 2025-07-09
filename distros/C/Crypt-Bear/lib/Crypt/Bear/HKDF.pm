package Crypt::Bear::HKDF;
$Crypt::Bear::HKDF::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: hkdf implementations in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::HKDF - hkdf implementations in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $hkdf = Crypt::Bear::HKDF->new('sha256', $salt);
 $hkdf->inject($data);
 $hkdf->flip;
 say unpack 'H*', $hkdf->produce(512, '');

=head1 DESCRIPTION

HKDF is a Key Derivation Function defined by [RFC 5869](https://tools.ietf.org/html/rfc5869). It is based on HMAC, itself using an underlying hash function. Any hash function can be used, as long as it is compatible with the rules for the HMAC implementation (i.e. output size is 64 bytes or less, hash internal state size is 64 bytes or less, and the internal block length is a power of 2 between 16 and 256 bytes). HKDF has two phases:

=over 4

=item HKDF-Extract

The input data in ingested, along with a "salt" value.

=item HKDF-Expand

The output is produced, from the result of processing the input and salt, and using an extra non-secret parameter called "info".

=back

The "salt" and "info" strings are non-secret and can be empty. Their role is normally to bind the input and output, respectively, to conventional identifiers that qualify them within the used protocol or application.

Note that the HKDF total output size (the number of bytes that HKDF-Expand is willing to produce) is limited: if the hash output size is C<n> bytes, then the maximum output size is C<255*n>.

=head1 METHODS

=head2 new($digest, $salt)

Initialize an HKDF context, with a hash function, and the salt. This starts the HKDF-Extract process.

=head2 inject($data)

Inject more input bytes. This function may be called repeatedly if the input data is provided by chunks.

=head2 flip()

End the HKDF-Extract process, and start the HKDF-Expand process.

=head2 produce($output_size, $info)

Get the next bytes of output. This function may be called several times to obtain the full output by chunks. For correct HKDF processing, the same "info" string must be provided for each call.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
