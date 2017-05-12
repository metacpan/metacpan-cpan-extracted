package Crypt::OpenSSL::Blowfish::CFB64;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Crypt::OpenSSL::Blowfish::CFB64', $VERSION);

sub encrypt_hex {
	return join '', unpack 'H*', $_[0]->encrypt( $_[1] );
}

sub decrypt_hex {
	$_[0]->decrypt( pack 'H*', $_[1] );
}

1;
__END__

=head1 NAME

Crypt::OpenSSL::Blowfish::CFB64 - Blowfish CFB64 Algorithm using OpenSSL

=head1 SYNOPSIS

  use Crypt::OpenSSL::Blowfish::CFB64;
  
  my $crypt = Crypt::OpenSSL::Blowfish::CFB64->new($key);
  # or
  my $crypt = Crypt::OpenSSL::Blowfish::CFB64->new($key, $ivec = pack( C8 => 1,2,3,4,5,6,7,8 ));
  
  my $binary_data = $crypt->encrypt("source");
  my $hex_data = $crypt->encrypt_hex("source");

  my $source = $crypt->decrypt($binary_data);
  my $source = $crypt->decrypt_hex($hex_data);

=head1 DESCRIPTION

Crypt::OpenSSL::Blowfish::CFB64 implements the Blowfish cipher algorithm in CFB mode, using function C<BF_cfb64_encrypt> contained in the OpenSSL crypto library.

=head1 SEE ALSO

http://www.openssl.org/, man BF_cfb64_encrypt

=head1 AUTHOR

Mons Anderson, E<lt>mons@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Mons Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
