package Crypt::Cipher::Skipjack;

### BEWARE - GENERATED FILE, DO NOT EDIT MANUALLY!

use strict;
use warnings;
our $VERSION = '0.087';

use base qw(Crypt::Cipher);

sub blocksize      { Crypt::Cipher::blocksize('Skipjack')      }
sub keysize        { Crypt::Cipher::keysize('Skipjack')        }
sub max_keysize    { Crypt::Cipher::max_keysize('Skipjack')    }
sub min_keysize    { Crypt::Cipher::min_keysize('Skipjack')    }
sub default_rounds { Crypt::Cipher::default_rounds('Skipjack') }

1;

=pod

=head1 NAME

Crypt::Cipher::Skipjack - Symmetric cipher Skipjack, key size: 80 bits

=head1 SYNOPSIS

  ### example 1
  use Crypt::Mode::CBC;

  my $key = '...'; # length has to be valid key size for this cipher
  my $iv = '...';  # 16 bytes
  my $cbc = Crypt::Mode::CBC->new('Skipjack');
  my $ciphertext = $cbc->encrypt("secret data", $key, $iv);

  ### example 2 (slower)
  use Crypt::CBC;
  use Crypt::Cipher::Skipjack;

  my $key = '...'; # length has to be valid key size for this cipher
  my $iv = '...';  # 16 bytes
  my $cbc = Crypt::CBC->new( -cipher=>'Cipher::Skipjack', -key=>$key, -iv=>$iv );
  my $ciphertext = $cbc->encrypt("secret data");

=head1 DESCRIPTION

This module implements the Skipjack cipher. Provided interface is compliant with L<Crypt::CBC|Crypt::CBC> module.

B<BEWARE:> This module implements just elementary "one-block-(en|de)cryption" operation - if you want to
encrypt/decrypt generic data you have to use some of the cipher block modes - check for example
L<Crypt::Mode::CBC|Crypt::Mode::CBC>, L<Crypt::Mode::CTR|Crypt::Mode::CTR> or L<Crypt::CBC|Crypt::CBC> (which will be slower).

=head1 METHODS

=head2 new

 $c = Crypt::Cipher::Skipjack->new($key);
 #or
 $c = Crypt::Cipher::Skipjack->new($key, $rounds);

=head2 encrypt

 $ciphertext = $c->encrypt($plaintext);

=head2 decrypt

 $plaintext = $c->decrypt($ciphertext);

=head2 keysize

  $c->keysize;
  #or
  Crypt::Cipher::Skipjack->keysize;
  #or
  Crypt::Cipher::Skipjack::keysize;

=head2 blocksize

  $c->blocksize;
  #or
  Crypt::Cipher::Skipjack->blocksize;
  #or
  Crypt::Cipher::Skipjack::blocksize;

=head2 max_keysize

  $c->max_keysize;
  #or
  Crypt::Cipher::Skipjack->max_keysize;
  #or
  Crypt::Cipher::Skipjack::max_keysize;

=head2 min_keysize

  $c->min_keysize;
  #or
  Crypt::Cipher::Skipjack->min_keysize;
  #or
  Crypt::Cipher::Skipjack::min_keysize;

=head2 default_rounds

  $c->default_rounds;
  #or
  Crypt::Cipher::Skipjack->default_rounds;
  #or
  Crypt::Cipher::Skipjack::default_rounds;

=head1 SEE ALSO

=over

=item * L<CryptX|CryptX>, L<Crypt::Cipher>

=item * L<https://en.wikipedia.org/wiki/Skipjack_(cipher)>

=back

=cut
