package Crypt::Keyczar::Verifier;
use base 'Crypt::Keyczar';
use strict;
use warnings;
use Carp;


sub verify {
    my $self = shift;
    my ($data, $signature, $hidden) = @_;

    if (!defined $signature || length $signature < Crypt::Keyczar::HEADER_SIZE()) {
        croak "signature is short";
    }

    my $hash_size = Crypt::Keyczar::KEY_HASH_SIZE();
    my ($v, $hash, $mac) = unpack "C1 a$hash_size a*", $signature;
    if ($v != Crypt::Keyczar::FORMAT_VERSION()) {
        croak "bad format version: $v";
    }
    my $key = $self->get_key($hash);
    if (!$key) {
        croak "key not found"; 
    }

    my $engine = $key->get_engine();
    my $expiration_time;
    if ($key->can('digest_size') && length $mac > $key->digest_size) {
        ($expiration_time, $mac) = unpack "N1 a*", $mac;
        $engine->update(pack 'N1', $expiration_time);
    }
    if (defined $hidden && length $hidden > 0) {
        $engine->update($hidden);
    }
    $engine->update($data);
    $engine->update(Crypt::Keyczar::FORMAT_BYTES());
    my $result = $engine->verify($mac);
    return $result if !$result;
    if (defined $expiration_time) {
        return time() < $expiration_time;
    }
    return $result;
}

1;
__END__

=head1 NAME

Crypt::Keyczar::Verifier - Verify data usign sets of symmetric or asymmetric keys.

=head1 SYNOPSIS

  use Crypt::Keyczar::Verifier;

  my $verifier = Crypt::Keyczar::Verifier->new('/path/to/keyset');
  $verifier->verify($message, $signature) ? 'OK' : 'NG';

=head1 DESCRIPTION

L<Crypt::Keyczar::Verifier> are used strictly to verify signatures. Typically, Verifiers will read sets of public keys, although may also be instantiated with sets of symmetric or private keys.

=head1 METHOD

=over 4

* new($keyset_path)

Create a new L<Crypt::Keyczar::Verifier> object with a file-based key set location. This will attempt to read the keys using a L<Crypt::Keyczar::FileReader>. The corresponding key set must have a purpose of either 'VERIFY' or 'SIGN_AND_VERIFY'.

* new($reader_object)

Create a new L<Crypt::Keyczar::Verifier> object with a L<Crypt::Keyczar::Reader> object.

* verify($message, $signature)

Verifies a I<$sigunature> on the given I<$message>.

=back 4

=head1 SEE ALSO

L<bin/keyczar>,
L<Crypt::Keyczar>,
L<Crypt::Keyczar::Signer>,
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
