package Crypt::Sodium::Nitrate;
use strict;
use warnings;

our $VERSION = '0.01';

use XSLoader ();

XSLoader::load(__PACKAGE__);

1;
__END__
=encoding utf-8

=pod

=head1 NAME

Crypt::Sodium::Nitrate - Don't let your sodium levels get too high!

=head1 DESCRIPTION

A thin wrapper around libsodium, exposing only the minimum
necessary to use the sodium secretbox.

This module was derived from code in L<Crypt::NaCl::Sodium>,
particularly L<Crypt::NaCl::Sodium::secretbox>.  Head over
there for a more extensive interface to libsodium!

The main difference is that C<Crypt::Sodium::Nitrate> does B<not> use protected
memory to store the encrypted/decrypted value;  everything
is done in Perl-allocated memory.

=head1 FUNCTIONS

=head2 decrypt($ciphertext, $nonce, $key)

Throws an exception if $ciphertext cannot be decrypted.

=head2 encrypt($plaintext, $nonce, $key)

Decrypts the value.

=head2 MACBYTES

Size of the MAC

=head2 KEYBYTES

Size of the key

=head2 NONCEBYTES

Size of the nonce

=cut


