package Crypt::Keyczar::Encrypter;
use base 'Crypt::Keyczar';
use strict;
use warnings;
use Carp;


sub encrypt {
    my $self = shift;
    my $result = '';
    my $key = $self->get_key($self->primary);
    if (!$key) {
        croak "no primary key";
    }
    my $crypt = $key->get_engine();
    my $signer = $key->get_sign_engine();
    $result .= $key->get_header();
    $result .= $crypt->init(); # set iv?
    $result .= $crypt->encrypt($_[0]);
    $signer->update($result);
    $result .= $signer->sign();
    return $result;
}


1;
__END__

=head1 NAME

Crypt::Keyczar::Encrypter - used strictly to encrypt data

=head1 SYNOPSIS

  use Crypt::Keyczar::Encrypter;
  
  my $encrypter = Crypt::Keyczar::Encrypter->new('/path/to/keyset');
  my $cipher_text = $encrypter->encrypt('Secret message');

  use Crypt::Keyczar::FileReader;
  my $key_reader = Crypt::Keyczar::FileReader->new('/path/to/keyset');
  $encrypter = Crypt::Keyczar::Encrypter->new($key_reader);
  $cipher_text = $encrypter->encrypt('Secret message');

=head1 DESCRIPTION

L<Crypt::Keyczar::Encrypter> are used strictly to encrypt data. Typically, Encrypters will read sets of symmetric keys, although may also be instantiated with set of public keys.

=head1 METHODS

=over 4

* new($keyset_path)

Create a new Encrypter with a file-based keyset location. This will attempt to read the keys using a L<Crypt::Keyczar::FileReader>. The corresponding key set must have a purpose of either I<crypt>.

* encrypt($input)

Encrypt the given I<$input>. return the encrypted cipher text.

=back 4

=head1 SEE ALSO

L<bin/keyczar>,
L<Crypt::Keyczar>,
L<Crypt::Keyczar::Crypter>,
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
