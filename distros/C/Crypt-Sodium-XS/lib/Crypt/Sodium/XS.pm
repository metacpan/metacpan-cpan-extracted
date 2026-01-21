package Crypt::Sodium::XS;
BEGIN {
  # BEGIN block and use line for MemVault are for its overloads to work
  our $VERSION = '0.001000';
  require XSLoader;
  XSLoader::load(__PACKAGE__, $VERSION);
}
use strict;
use warnings;

use Exporter 'import';
use Crypt::Sodium::XS::MemVault;
use parent 'Crypt::Sodium::XS::Base';

_define_constants();

our %EXPORT_TAGS = (
  functions => [qw[sodium_version_string]],
  constants => [qw[
    SODIUM_VERSION_STRING
    SODIUM_LIBRARY_VERSION_MAJOR
    SODIUM_LIBRARY_VERSION_MINOR
  ]],
);
$EXPORT_TAGS{all} = [@{$EXPORT_TAGS{functions}}, @{$EXPORT_TAGS{constants}}];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

# NB: Crypt::Sodium::XS::Protmem import not necessary, calling XSUBs directly.
if (exists $ENV{PROTMEM_FLAGS_KEY}) {
  Crypt::Sodium::XS::ProtMem::protmem_default_flags_key($ENV{PROTMEM_FLAGS_KEY});
}
if (exists $ENV{PROTMEM_FLAGS_DECRYPT}) {
  Crypt::Sodium::XS::ProtMem::protmem_default_flags_decrypt($ENV{PROTMEM_FLAGS_DECRYPT});
}
if (exists $ENV{PROTMEM_FLAGS_STATE}) {
  Crypt::Sodium::XS::ProtMem::protmem_default_flags_state($ENV{PROTMEM_FLAGS_STATE});
}
if (exists $ENV{PROTMEM_FLAGS_MEMVAULT}) {
  Crypt::Sodium::XS::ProtMem::protmem_default_flags_memvault($ENV{PROTMEM_FLAGS_MEMVAULT});
}
if (exists $ENV{PROTMEM_FLAGS_ALL}) {
  Crypt::Sodium::XS::ProtMem::protmem_default_flags_key($ENV{PROTMEM_FLAGS_ALL});
  Crypt::Sodium::XS::ProtMem::protmem_default_flags_decrypt($ENV{PROTMEM_FLAGS_ALL});
  Crypt::Sodium::XS::ProtMem::protmem_default_flags_state($ENV{PROTMEM_FLAGS_ALL});
  Crypt::Sodium::XS::ProtMem::protmem_default_flags_memvault($ENV{PROTMEM_FLAGS_ALL});
}

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS - perl XS bindings for libsodium

=head1 SYNOPSIS

  ### authenticated symmetric encryption

  use Crypt::Sodium::XS;

  my $secretbox = Crypt::Sodium::XS->secretbox;

  my $key = $secretbox->keygen;
  my $nonce = $secretbox->nonce;

  my $ciphertext = $secretbox->encrypt("hello", $nonce, $key);
  my $plaintext = $secretbox->decrypt($cipher_one, $nonce, $key);

  print $plaintext->unlock, "\n";
  undef $plaintext;

  ### authenticated asymmetric encryption

  use Crypt::Sodium::XS;

  # optionally choose a specific algorithm
  my $box = Crypt::Sodium::XS->box(algorithm => 'xchacha20poly1305');

  my ($alice_pk, $alice_sk) = $box->keypair;
  my ($bob_pk, $bob_sk) = $box->keypair;
  my $nonce = $box->nonce;

  my $ciphertext = $box->encrypt("see ya", $nonce, $alice_pk, $bob_sk);
  my $plaintext = $box->decrypt($cipher_one, $nonce, $bob_pk, $alice_sk);

  $plaintext->concat(" later!\n");
  print $plaintext->unlock;
  $plaintext->lock;

  ### passwords and generating arbitrary-length keys from passwords

  use Crypt::Sodium::XS::Util "sodium_memzero";

  my $pwhash = Crypt::Sodium::XS->pwhash;

  my $password = "foobar";
  my $password_hash_str = $pwhash->str($password);
  sodium_memzero($password);
  my $password_input = "foobar";
  die "denied" unless $pwhash->verify($password_hash_str, $password_input);
  sodium_memzero($password_input);

  my $passphrase = "barfoo";
  my $key_bytes_len = 32;
  my $special_key = $pwhash->pwhash($passphrase, $key_bytes_len);
  sodium_memzero($passphrase);

  # and much more...

=head1 DESCRIPTION

B<NOTE>: This distribution is new and should be considered experimental. Not
recommended for "production" use. There are likely bugs and undesirable
behaviors yet to be discovered.

L<Sodium|https://libsodium.org> is a modern, easy-to-use software library for
encryption, decryption, signatures, password hashing and more. Its goal is to
provide all of the core operations needed to build higher-level cryptographic
tools.

L<Crypt::Sodium::XS> provides an interface to the libsodium API. By default, it
uses hardened memory handling provided by libsodium for sensitive data. It is a
complete interface to the libsodium API, including algorithm-specific
functions.

=head1 FUNCTIONS

Nothing is exported by default. The tag C<:functions> imports all
L</FUNCTIONS>. The tag C<:all> imports everything.

=head2 sodium_version_string

Returns the currently used libsodium version, as a string.

=head1 CONSTANTS

Nothing is exported by default. The tag C<:constants> imports all
L</CONSTANTS>. The tag C<:all> imports everything.

=head2 SODIUM_LIBRARY_VERSION_STRING

A constant identical to L</sodium_version_string>.

=head2 SODIUM_LIBRARY_VERSION_MAJOR

libsodium shared object major version number.

=head2 SODIUM_LIBRARY_VERSION_MINOR

libsodium shared object minor version number.

=head1 MEMORY SAFETY

See L<Crypt::Sodium::XS::MemVault> for information about protected memory
objects. Also see L<Crypt::Sodium::XS::ProtMem> for detailed information on
how those objects are used and the memory protections provided by this
distribution.

Many functions and methods return sensitive data as
L<Crypt::Sodium::XS::MemVault> objects; the documentation will say so.

=head1 INSTALLATION

The default method of installation will attempt to detect a recent enough
version of libsodium headers on your system or fall back to a bundled version
of libsodium. You should prefer to install libsodium via your operating
system's package manager (be sure to install the "development" package) before
building this dist. If you instead fall back to the bundled libsodium, keep in
mind that it cannot be kept up to date without updating this perl package: see
below for how to update a bundled libsodium if a newer version of this package
is not available. The bundled libsodium is distributed in its original form
along with its OpenPGP signature file. You are encouraged to manually check its
signature.

You may prevent the automatic libsodium detection (forcing the use of the
bundled version) by setting the environment variable SODIUM_BUNDLED to any
true (perl's perspective) value.

  SODIUM_BUNDLED=1 cpanm Crypt::Sodium::XS

You may explicitly use a libsodium tarball of your choosing by setting the
SODIUM_BUNDLED environment variable to its absolute path. In this way, it is
possible to build this dist with a newer version of libsodium than it bundles.

  SODIUM_BUNDLED=$HOME/download/libsodium-x.y.z.tar.gz \
    cpanm --reinstall Crypt::Sodium::XS

If you prefer to use libsodium from a non-standard location or with special
linker options, you may set the C<SODIUM_INC> and/or C<SODIUM_LIBS> environment
variables. This will override the detection of libsodium and explicitly use the
given arguments. You should ensure the version of libsodium you intend to use
is the same as the bundled lib or higher. Older versions *may* work, but no
promises. For example, with libsodium installed in /opt/sodium you may want
something like:

  SODIUM_INC="-I/opt/sodium/include" \
  SODIUM_LIBS="-L/opt/sodium/lib -Wl,-rpath -Wl,/opt/sodium/lib -lsodium" \
  cpanm Crypt::Sodium::XS

=head1 PROCEDURAL vs. OBJECT ORIENTED

For all libsodium operations, there are both convenience objects wrapping the
API and exportable functions.

The procedural interface can give a very small performance improvement over
objects, if micro-optimization is important to your use of the library. The
object oriented interface can be more concise and easier to use, so it is
recommended for most use.

It is acceptable to mix and match the use of procedural and OO interfaces.

For each of the L</LIBSODIUM OPERATIONS>, L<Crypt::Sodium::XS> has a
constructor method. For example:

  my $box_obj = Crypt::Sodium::XS->box(%constructor_args);

=head1 LIBSODIUM OPERATIONS

The following libsodium operations are supported:

=over 4

=item * aead

Authenticated encryption with additional data

See L<Crypt::Sodium::XS::aead>.

=item * auth

Secret key message authentication

See L<Crypt::Sodium::XS::auth>.

=item * box

Public key authenticated or anonymous encryption

See L<Crypt::Sodium::XS::box>.

=item * curve25519

Low-level functions over Curve25519. Only for creating custom constructions.

See L<Crypt::Sodium::XS::curve25519>.

=item * generichash

Generic cryptographic hashing

See L<Crypt::Sodium::XS::generichash>.

=item * hash

SHA2 hashing

See L<Crypt::Sodium::XS::hash>.

=item * hkdf

(HMAC-based) Key derivation from a master key

See L<Crypt::Sodium::XS::hkdf>.

=item * kdf

Key derivation from a master key

See L<Crypt::Sodium::XS::kdf>.

=item * kx

Diffie-Hellman key exchange

See L<Crypt::Sodium::XS::kx>.

=item * onetimeauth

One-time secret key authentication

See L<Crypt::Sodium::XS::onetimeauth>.

=item * pwhash

Password hashing

See L<Crypt::Sodium::XS::pwhash>.

=item * shorthash

Short-input hashing

See L<Crypt::Sodium::XS::shorthash>.

=item * sign

Public key signatures

See L<Crypt::Sodium::XS::sign>.

=item * scalarmult

Point multiplication on the curve25519 curve (primitive for key exchange,
generating public key from secret key)

See L<Crypt::Sodium::XS::scalarmult>.

=item * secretbox

Secret key (symmetric) authenticated encryption

See L<Crypt::Sodium::XS::secretbox>.

=item * secretstream

Secret key (symmetric) authenticated message streams with additional data

See L<Crypt::Sodium::XS::secretstream>.

=item * stream

Unauthenticated secret key encryption suitable only for pseudorandom
generation, or as a primitive for higher-level construction

See L<Crypt::Sodium::XS::stream>.

=back

=head1 ALGORITHMS

Much of the libsodium functionality is provided with easy-to-use interfaces
which make carefully considered choices about default algorithms. This
distribution intends to follow the upstream library's choices, providing access
to all of the algorithm-specific functions as well as the generic ones. In some
cases (L<Crypt::Sodium::XS::aead> and L<Crypt::Sodium::secretstream>),
libsodium does not provide generic interfaces, and this distribution follows
suit. It is anticipated that libsodium may in the future decide to provide a
different algorithm as the default. In other cases, libsodium provides only the
generic interfaces. For these, L<Crypt::Sodium::XS> adds the algorithm-specifc
function names since that should have no effect on forward-compatibility.

When using these modules, keep in mind that libsodium intends to keep all the
default algorithms the same between major versions of the library, but reserves
the possibility of changing defaults between major library versions. Depending
on your needs, it might be wise to use the algorithm-specific variants of
functions, even when that is currently the default algorithm. This can help
keep forward-compatibility if defaults are changed. One should also consider
using version headers or other application-specific means to ensure algorithm
changes can be made non-disruptively in the future.

=head1 BUGS/KNOWN LIMITATIONS

In general, L<Crypt::Sodium::XS> is not intendend for a multi-threaded
environment.

This distribution is developed on Linux. Portability has been a low priority,
and there are likely to be bugs for non-POSIXish systems. No testing on windows
has been done, and it likely doesn't work. Feedback, suggestions, and patches
are appreciated!

=head1 SEE ALSO

=over 4

=item * L<Crypt::Sodium::XS::ProtMem>

Functions and constants for memory protection

=item * L<Crypt::Sodium::XS::MemVault>

Protected memory objects

=item * L<Crypt::Sodium::XS::Base64>

base64 utilities and constants from libsodium

=item * L<Crypt::Sodium::XS::Util>

Utilities from libsodium

=item * L<libsodium|https://doc.libsodium.org>

=item * L<Crypt::NaCl::Sodium>

=back

=head1 FEEDBACK

For reporting bugs, giving feedback, submitting patches, etc. please use the
following:

=over 4

=item *

RT queue at L<https://rt.cpan.org/Dist/Display.html?Name=Crypt-Sodium-XS>

=item *

IRC channel C<#sodium> on C<irc.perl.org>.

=item *

Email the author directly.

=back

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 THANKS

Thanks to Frank Denis for L<libsodium|https://libsodium.org/>.

Thanks to Alex J. G. Burzyński for L<Crypt::NaCl::Sodium>, which inspired
writing this.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

libsodium is Copyright (c) 2013-2024 Frank Denis <j at pureftpd dot org>

Redistributed with this library under the ISC License. See the LICENSE file of
the bundled software.

=cut
