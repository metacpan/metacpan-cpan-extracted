package AES128;

use 5.016001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use AES128 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	AES128_CTR_encrypt AES128_CTR_decrypt	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('AES128', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

AES128 - 128BIT CTR mode AES algorithm. 

=head1 SYNOPSIS

	# ------------------------  simple version ----------------------------------
	use AES128 qw/:all/;
	my $plain_text = "There's more than one way to do it.";
	my $key = "my secret aes key.";
	my $encrypted = AES128_CTR_encrypt($plain_text, $key);
	my $plain     = AES128_CTR_decrypt($encrypted, $key);


	# ------------ server/client key exchange -----------------------------------
	use MicroECC;
	use AES128 qw/:all/;
	use Digest::SHA qw/sha256/;

	my $curve = MicroECC::secp256r1();
	my ($server_pubkey, $server_privkey) = MicroECC::make_key($curve);

	# Generate shared secret with client public key.
	my $shared_secret = MicroECC::shared_secret($client_pubkey, $server_privkey);
	my $key = sha256($shared_secret);

	my $plain_text = "There's more than one way to do it.";
	my $encrypted  = AES128_CTR_encrypt($plain_text, $key);
	my $plain      = AES128_CTR_decrypt($encrypted, $key);

=head1 DESCRIPTION

Perl wrapper for the tiny-AES-c library (https://github.com/kokke/tiny-AES-c)

Since 128bit key length is secure enough for most applications and ECB is NOT secure,
this module supports 128bit key length and CTR mode only.

=head2 EXPORT

None by default.


=head1 SEE ALSO

The tiny-AES-c library: https://github.com/kokke/tiny-AES-c

=head1 AUTHOR

Jeff Zhang, <10395708@qq.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
