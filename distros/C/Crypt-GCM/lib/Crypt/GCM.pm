package Crypt::GCM;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Crypt::GCM', $VERSION);


1;
__END__

=head1 NAME

Crypt::GCM - Galois/Counter Mode (GCM)

=head1 SYNOPSIS

  use Crypt::GCM;
  use Crypt::Rijndael;
  
  my $gcm = Crypt::GCM->new(-key => $key, -cipher => 'Crypt::Rijndael');
  my $gcm->set_iv($iv);
  my $gcm->aad('');
  my $cipher_string = $gcm->encrypt($message);
  my $tag = $gcm->tag;

=head1 DESCRIPTION

The module implements the Galois/Counter Mode (GCM) for Confidentiality and Authentication. The function of GCM in which the plaintext is encrypted into the ciphertext, and an authentication tag is generated on the AAD and the ciphertext.


=head2 new()

  my $cipher = Crypt::GCM->new(
      -key    => pack 'H*', '00000000000000000000000000000000',
      -cipher => 'Crypt::Rijndael',
  );

The new() method creates an new Crypt::GCM object. It accepts a list of -argument => value pairs selected from the following list:

  Argument     Description
  --------     -----------
  -key         The encryption/decryption key (required)
  
  -cipher      The cipher algorithm (required)
  
=head2 encrypt()

  my $ciphertext = $cipher->encrypt($plaintext);

=head2 decrypt()

  my $plaintext = $cipher->decrypt($ciphertext);

=head2 set_iv()

  $cipher->set_iv($iv);

This allows you to change the initialization vector. allow 16byte string.

=head2 aad()

  $cipher->aad($text);
  my $text = $cipher->aad();

=head2 tag()

  $cipher->tag($tag);
  my $tag = $cipher->tag();

=head1 EXAMPLE

=head2 Encrypt

  use Crypt::GCM;
  use Crypt::Rijndael;
  use strict;
  
  my $cipher = Crypt::GCM->new(
      -key => pack 'H*', '00000000000000000000000000000000',
      -cipher => 'Crypt::Rijndael',
  );
  $cipher->set_iv(pack 'H*', '000000000000000000000000');
  $cipher->aad('');
  my $ciphertext = $cipher->encrypt(pack 'H*', '000000000000000000000000000000');
  my $tag = $cipher->tag;

=head2 Decrypt

  use Crypt::GCM;
  use Crypt::Rijndael;
  use strict;
  
  my $cipher = Crypt::GCM->new(
      -key => pack 'H*', '00000000000000000000000000000000',
      -cipher => 'Crypt::Rijndael',
  );
  $cipher->set_iv(pack 'H*', '000000000000000000000000');
  $cipher->aad('');
  $cipher->tag(pack 'H*', 'ab6e47d42cec13bdf53a67b21257bddf');
  my $plaintext = $cipher->decrypt(pack 'H*', '0388dace60b6a392f328c2b971b2fe78');
  if (!defined $plaintext) {
      die 'cannot decrypt on GCM mode. please check your Authentication Tag';
  }

=head1 SEE ALSO

NIST Special Publication 800-38D - Recommendation for Block Cipher Modes of Operation: Galois/Counter Mode (GCM) for Confidentiality and Authenticaton.

L<http://csrc.nist.gov/publications/drafts/Draft-NIST_SP800-38D_Public_Comment.pdf>

=head1 AUTHOR

Hiroyuki OYAMA, E<lt>oyama@module.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Hiroyuki OYAMA.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
