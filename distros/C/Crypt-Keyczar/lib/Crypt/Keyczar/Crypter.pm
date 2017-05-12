package Crypt::Keyczar::Crypter;
use base 'Crypt::Keyczar::Encrypter';
use strict;
use warnings;
use Crypt::Keyczar qw(HEADER_SIZE KEY_HASH_SIZE FORMAT_VERSION);
use Carp;


sub decrypt {
    my $self = shift;
    my $data = shift;

    if (length $data < HEADER_SIZE()) {
        croak "signature is short";
    }
    my $hash_size = KEY_HASH_SIZE();
    my ($v, $hash, $body) = unpack "C1 a$hash_size a*", $data;
    if ($v != FORMAT_VERSION()) {
        croak "bad format version: $v";
    }
    my $key = $self->get_key($hash);
    if (!$key) {
        croak "key not found";
    }

    my $engine = $key->get_engine();
    my $mac    = $key->get_sign_engine();
    my $cipher_body = substr $body, 0, $mac->digest_size()*-1;
    my $signature   = substr $body, $mac->digest_size()*-1;
    my $iv = $engine->init($cipher_body); 
    my $cipher_text = length $iv > 0 ? substr($cipher_body, length $iv) : $body;
    my $plain_text = $engine->decrypt($cipher_text);
    my $signed_text = substr $data, 0, $mac->digest_size()*-1;
    $mac->update($signed_text);
    if (!$mac->verify($signature)) {
        croak "invalid signature";
    }

    return $plain_text;
}

1;
__END__

=head1 NAME

Crypt::Keyczar::Crypter - Crypter may both encrypt and decrypt data.

=head1 SYNOPSIS

  use Crypt::Keyczar::Crypter;
  
  my $crypter = Crypt::Keyczar::Crypter->new('/path/to/keysets');
  my $ciphertext = $crypter->encrypt('Secret message');
  my $plain_text = $crypter->decrypt($ciphertext);

=head1 DESCRIPTION

L<Crypt::Keyczar::Crypter> may both encrypt and decrypt data using sets of symmetric or private keys. Sets of public keys may only be used with L<Crypt::Keyczar::Encrypter> objects.

=head1 METHODS

=over 4

* new($keyset_path)

Create a new L<Crypt::Keyczar::Crypter> with file-based keyset location. This will attempt to read the keys using a L<Crypt::Keyczar::FileReader>. The corresponding key set must have a purpose of I<crypt>.

* new($reader_object)

Create a new L<Crypt::Keyczar::Crypter> with a B<Crypt::Keyczar::Reader> object.

* encrypt($input)

Encrypt the given I<$input>. return the encrypted cipher text.

* decrypt($input)

Decrypt the given I<$input> ciphertext. return the decrypted plain text.

=back 4

=head1 SEE ALSO

L<bin/keyczar>,
L<Crypt::Keyczar>,
L<Crypt::Keyczar::Encrypter>,
L<http://www.keyczar.org/>

=head1 AUTHOR

Hiroyuki OYAMA <oyama@mixi.co.jp>

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
