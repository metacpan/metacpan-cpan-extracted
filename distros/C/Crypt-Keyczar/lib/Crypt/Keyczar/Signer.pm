package Crypt::Keyczar::Signer;
use base 'Crypt::Keyczar::Verifier';
use strict;
use warnings;
use Carp;


sub sign {
    my $self = shift;
    my ($data, $expiration_time, $hidden) = @_;
    my $result = '';

    my $key = $self->get_key($self->primary);
    if (!$key) {
        croak "no primary key";
    }

    $result .= $key->get_header();
    my $engine = $key->get_engine;
    if (defined $expiration_time && $expiration_time > 0) {
        my $expiration = pack 'N1', $expiration_time;
        $engine->update($expiration);
        $result .= $expiration;
    }
    if (defined $hidden && length $hidden > 0) {
        $engine->update($hidden);
    }
    $engine->update($data);
    $engine->update(Crypt::Keyczar::FORMAT_BYTES());
    $result .= $engine->sign();

    return $result;
}

1;
__END__

=head1 NAME

Crypt::Keyczar::Signer - Sign and Verify data using sets of symmetric or private keys.

=head1 SYNOPSIS

  use Crypt::Keyczar::Signer;
  
  my $signer = Crypt::Keyczar::Signer->new('/path/to/keyset');
  my $signature = $signer->sign($message);
  $signer->verify($message, $signature) ? 'OK' : 'NG';

=head1 DESCRIPTION

L<Crypt::Keyczar::Signer> may both sign and verify data using sets of symmetric or private keys. Sets of public keys may only used with L<Crypt::Keyczar::Verifier> objects.
L<Crypt::Keyczar::Singer> objects should be used with symmetric or private key sets to generate signatures.

=head1 METHODS

=over 4

* new($keyset_path)

Create a new L<Crypt::Keyczar::Signer> object with a file-based key set location. This will attempt to read the keys using a L<Crypt::Keyczar::FileReader>. The corresponsing key set must have a purpose of I<crypt>.
I<$keyset_path> is directory containing a key set.

* new($reader_object)

Create a new L<Crypt::Keyczar::Signer> object with a L<Crypt::Keyczar::Reader> object.

* sign($message)

Sign the given I<$message> and return a signature.

* sign($message, $expiration_time)

Sign the given I<$message> and return a signature with expiration.

* verify($message, $signature>)

Verifies a I<$signature> on the given I<$message>.

=back 4

=head1 SEE ALSO

L<bin/keyczar>,
L<Crypt::Keyczar>,
L<Crypt::Keyczar::Verifier>,
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
