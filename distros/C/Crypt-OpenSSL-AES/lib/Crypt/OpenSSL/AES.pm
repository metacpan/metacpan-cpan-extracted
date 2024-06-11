package Crypt::OpenSSL::AES;

# Copyright (C) 2006 - 2024 DelTel, Inc.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.5 or,
# at your option, any later version of Perl 5 you may have available.

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.21';

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::OpenSSL::AES ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

require XSLoader;
XSLoader::load('Crypt::OpenSSL::AES', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Crypt::OpenSSL::AES - A Perl wrapper around OpenSSL's AES library

=head1 SYNOPSIS

     use Crypt::OpenSSL::AES;

     my $cipher = Crypt::OpenSSL::AES->new($key);

     or

     # Pick better keys and iv...
     my $key = pack("H*", substr(sha512_256_hex(rand(1000)), 0, ($ks/4)));
     my $iv  = pack("H*", substr(sha512_256_hex(rand(1000)), 0, 32));
     my $cipher = Crypt::OpenSSL::AES->new(
                                            $key,
                                            {
                                                cipher => 'AES-256-CBC',
                                                iv      => $iv, (16-bytes for supported ciphers)
                                                padding => 1, (0 - no padding, 1 - padding)
                                            }
                                        );

     $encrypted = $cipher->encrypt($plaintext);
     $decrypted = $cipher->decrypt($encrypted);

=head1 DESCRIPTION

This module implements a wrapper around OpenSSL.  Specifically, it
wraps the methods related to the US Government's Advanced
Encryption Standard (the Rijndael algorithm).  The original version
supports only AES ECB (electronic codebook mode encryption).

This module is compatible with Crypt::CBC (and likely other modules
that utilize a block cipher to make a stream cipher).

This module is an alternative to the implementation provided by
Crypt::Rijndael which implements AES itself. In contrast, this module
is simply a wrapper around the OpenSSL library.

As of version 0.09 additional AES ciphers are supported.  Those are:

=over 4

=item Block Ciphers

The blocksize is 16 bytes and must be padded if not a multiple of the
blocksize.

=over 4

=item AES-128-ECB, AES-192-ECB and AES-256-ECB (no IV)

Supports padding

=item AES-128-CBC, AES-192-CBC and AES-256-CBC

Supports padding and iv

=back

=back

=over 4

=item Stream Ciphers

The blocksize is 1 byte. OpenSSL does not pad even if padding
is set (the default).

=over 4

=item AES-128-CFB, AES-192-CFB and AES-256-CFB

Supports iv

=item AES-128-CTR, AES-192-CTR and AES-256-CTR

Supports iv

=item AES-128-OFB, AES-192-OFB and AES-256-OFB

Supports iv

=back

=back

=over 4

=item new()

For compatibility with old versions you can simply pass the key to the
new constructor.

    # The default cipher is AES-ECB based on the key size
    my $cipher = Crypt::OpenSSL::AES->new($key);

    or

    # the keysize must match the cipher size
    # 16-bytes (128-bits) AES-128-xxx
    # 24-bytes (192-bits) AES-192-xxx
    # 32-bytes (256-bits) AES-256-xxx
    my $cipher = Crypt::OpenSSL::AES->new($key,
                    {
                        cipher  => 'AES-256-CBC',
                        iv      => $iv, (16-bytes for supported ciphers)
                        padding => 1, (0 - no padding, 1 - padding)
                    });

    # cipher
    #   AES-128-ECB, AES-192-ECB and AES-256-ECB (no IV)
    #   AES-128-CBC, AES-192-CBC and AES-256-CBC
    #   AES-128-CFB, AES-192-CFB and AES-256-CFB
    #   AES-128-CTR, AES-192-CTR and AES-256-CTR
    #   AES-128-OFB, AES-192-OFB and AES-256-OFB
    #
    # iv - 16-byte random data
    #
    # padding
    #   0 - no padding
    #   1 - padding

=item $cipher->encrypt($data)

Encrypt data. For Block Ciphers (ECB and CBC) the size of C<$data>
must be exactly C<blocksize> in length (16 bytes) B<or> padding must be
enabled in the B<new> constructor, otherwise this function will croak.

For Stream ciphers (CFB, CTR or OFB) the block size is considered to
be 1 byte and no padding is required.

Crypt::CBC is no longer required to encrypt/decrypt data of arbitrary
lengths.

=item $cipher->decrypt($data)

Decrypts data. For Block Ciphers (ECB and CBC) the size of C<$data>
must be exactly C<blocksize> in length (16 bytes) B<or> padding must be
enabled in the B<new> constructor, otherwise this function will croak.

For Stream ciphers (CFB, CTR or OFB) the block size is considered to
be 1 byte and no padding is required.

Crypt::CBC is no longer required to encrypt/decrypt data of arbitrary
lengths.

=item keysize

This method is used by Crypt::CBC to verify the key length.
This module actually supports key lengths of 16, 24, and 32 bytes,
but this method always returns 32 for Crypt::CBC's sake.

=item blocksize

This method is used by Crypt::CBC to check the block size.
The blocksize for AES is always 16 bytes.

=back

=head2 USE WITH CRYPT::CBC

As padding is now supported for the CBC cipher, Crypt::CBC is no
longer required but supported for backward compatibility.

	use Crypt::CBC;

	my $plaintext = "This is a test!!";
	my $password = "qwerty123";
	my $cipher = Crypt::CBC->new(
		-key    => $password,
		-cipher => "Crypt::OpenSSL::AES",
		-pbkdf  => 'pbkdf2',
	);

	my $encrypted = $cipher->encrypt($plaintext);
	my $decrypted = $cipher->decrypt($encrypted);

=head1 SEE ALSO

L<Crypt::CBC>

http://www.openssl.org/

http://en.wikipedia.org/wiki/Advanced_Encryption_Standard

http://www.csrc.nist.gov/encryption/aes/

=head1 BUGS

Need more (and better) test cases.

=head1 AUTHOR

Tolga Tarhan, E<lt>cpan at ttar dot orgE<gt>

The US Government's Advanced Encryption Standard is the Rijndael
Algorithm and was developed by Vincent Rijmen and Joan Daemen.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 - 2024 DelTel, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
