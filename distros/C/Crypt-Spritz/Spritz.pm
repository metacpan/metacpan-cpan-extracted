=head1 NAME

Crypt::Spritz - Spritz stream cipher/hash/MAC/AEAD/CSPRNG family

=head1 SYNOPSIS

 use Crypt::Spritz;

 # see the commented examples in their respective classes,
 # but basically

 my $cipher = new Crypt::Spritz::Cipher::XOR $key, $iv;
 $ciphertext = $cipher->crypt ($cleartext);

 my $cipher = new Crypt::Spritz::Cipher $key, $iv;
 $ciphertext  = $cipher->encrypt ($cleartext);
 # $cleartext = $cipher->decrypt ($ciphertext);

 my $hasher = new Crypt::Spritz::Hash;
 $hasher->add ($data);
 $digest = $hasher->finish;

 my $hasher = new Crypt::Spritz::MAC $key;
 $hasher->add ($data);
 $mac = $hasher->finish;

 my $prng = new Crypt::Spritz::PRNG $entropy;
 $prng->add ($additional_entropy);
 $keydata = $prng->get (32);

 my $aead = new Crypt::Spritz::AEAD::XOR $key;
 $aead->nonce ($counter);
 $aead->associated_data ($header);
 $ciphertext = $aead->crypt ($cleartext);
 $mac = $aead->mac;

 my $aead = new Crypt::Spritz::AEAD $key;
 $aead->nonce ($counter);
 $aead->associated_data ($header);
 $ciphertext  = $aead->encrypt ($cleartext);
 # $cleartext = $aead->decrypt ($ciphertext);
 $mac = $aead->mac;

=head1 WARNING

The best known result (early 2017) against Spritz is a distinguisher
attack on 2**44 outputs with multiple keys/IVs, and on 2**60 outputs with
a single key (see doi:10.1007/978-3-662-52993-5_4 for details). These are
realistic attacks, so Spritz needs to be considered broken, although for
low data applications it should still be useful.

=head1 DESCRIPTION

This module implements the Spritz spongelike function (with N=256), the
spiritual successor of RC4 developed by Ron Rivest and Jacob Schuldt.

Its strength is extreme versatility (you get a stream cipher, a hash, a
MAC, a DRBG/CSPRNG, an authenticated encryption block/stream cipher and
more) and extremely simple and small code (encryption and authentication
can be had in 1KB of compiled code on amd64, which isn't an issue for most
uses in Perl, but is useful in embedded situations, or e.g. when doing
crypto using javascript in a browser and communicating with Perl).

Its weakness is its relatively slow speed (encryption is a few times
slower than RC4 or AES, hashing many times slower than SHA-3, although
this might be reversed on an 8-bit-cpu) and the fact that it is totally
unproven in the field (as of this writing, the cipher was just a few
months old), so it can't be called production-ready.

All the usual caveats regarding stream ciphers apply - never repeat your
key, never repeat your nonce and so on - you should have some basic
understanding of cryptography before using this cipher in your own
designs.

The Spritz base class is not meant for end users. To make usage simpler
and safer, a number of convenience classes are provided for typical
end-user tasks:

   random number generation - Crypt::Spritz::PRNG
   hashing                  - Crypt::Spritz::Hash
   message authentication   - Crypt::Spritz::MAC
   encryption               - Crypt::Spritz::Cipher::XOR
   encryption               - Crypt::Spritz::Cipher
   authenticated encryption - Crypt::Spritz::AEAD::XOR
   authenticated encryption - Crypt::Spritz::AEAD

=cut

package Crypt::Spritz;

use XSLoader;

$VERSION = 1.02;

XSLoader::load __PACKAGE__, $VERSION;

@Crypt::Spritz::ISA              = Crypt::Spritz::Base::;

@Crypt::Spritz::Hash::ISA        =
@Crypt::Spritz::PRNG::ISA        =
@Crypt::Spritz::Cipher::ISA      =
@Crypt::Spritz::AEAD::ISA        = Crypt::Spritz::Base::;

@Crypt::Spritz::MAC::ISA         = Crypt::Spritz::Hash::;

@Crypt::Spritz::Cipher::XOR::ISA = Crypt::Spritz::Cipher::;
@Crypt::Spritz::AEAD::XOR::ISA   = Crypt::Spritz::AEAD::;

sub Crypt::Spritz::Cipher::keysize   () { 32 }
sub Crypt::Spritz::Cipher::blocksize () { 64 }

*Crypt::Spritz::Hash::new = \&Crypt::Spritz::new;

*Crypt::Spritz::Hash::add =
*Crypt::Spritz::PRNG::add = \&Crypt::Spritz::absorb;

*Crypt::Spritz::PRNG::get = \&Crypt::Spritz::squeeze;

*Crypt::Spritz::AEAD::new             = \&Crypt::Spritz::MAC::new;
*Crypt::Spritz::AEAD::finish          = \&Crypt::Spritz::Hash::finish;

*Crypt::Spritz::AEAD::associated_data =
*Crypt::Spritz::AEAD::nonce           = \&Crypt::Spritz::absorb_and_stop;


=head2 THE Crypt::Spritz CLASS

This class implements most of the Spritz primitives. To use it effectively
you should understand them, for example, by reading the L<Spritz
paper|http://people.csail.mit.edu/rivest/pubs/RS14.pdf>, especially
pp. 5-6.

The Spritz primitive corresponding to the Perl method is given as
comment.

=over 4

=item $spritz = new Crypt::Spritz   # InitializeState

Creates and returns a new, initialised Spritz state.

=item $spritz->init                 # InitializeState

Initialises the Spritz state again, throwing away the previous state.

=item $another_spritz = $spritz->clone

Make an exact copy of the spritz state. This method can be called on all
of the objects in this module, but is documented separately to give some
cool usage examples.

=item $spritz->update               # Update

=item $spritz->whip ($r)            # Whip

=item $spritz->crush                # Crush

=item $spritz->shuffle              # Shuffle

=item $spritz->output               # Output

Calls the Spritz primitive ovf the same name - these are not normally
called manually.

=item $spritz->absorb ($I)          # Absorb

Absorbs the given data into the state (usually used for key material,
nonces, IVs messages to be hashed and so on).

=item $spritz->absorb_stop          # AbsorbStop

Absorbs a special stop symbol - this is usually used as delimiter between
multiple strings to be absorbed, to thwart extension attacks.

=item $spritz->absorb_and_stop ($I)

This is a convenience function that simply calls C<absorb> followed by
C<absorb_stop>.

=item $octet = $spritz->drip        # Drip

Squeezes out a single byte from the state.

=item $octets = $spritz->squeeze ($len) # Squeeze

Squeezes out the requested number of bytes from the state - this is usually

=back


=head2 THE Crypt::Spritz::PRNG CLASS

This class implements a Pseudorandom Number Generatore (B<PRNG>),
sometimes also called a Deterministic Random Bit Generator (B<DRBG>). In
fact, it is even cryptographically secure, making it a B<CSPRNG>.

Typical usage as a random number generator involves creating a PRNG
object with a seed of your choice, and then fetching randomness via
C<get>:

   # create a PRNG object, use a seed string of your choice
   my $prng = new Crypt::Spritz::PRNG $seed;

   # now call get as many times as you wish to get binary randomness
   my $some_randomness = $prng->get (17);
   my moree_randomness = $prng->get (5000);
   ...

Typical usage as a cryptographically secure random number generator is to
feed in some secret entropy (32 octets/256 bits are commonly considered
enough), for example from C</dev/random> or C</dev/urandom>, and then
generate some key material.

   # create a PRNG object
   my $prng = new Crypt::Spritz::PRNG;

   # seed some entropy (either via ->add or in the constructor)
   $prng->add ($some_secret_highly_entropic_string);

   # now call get as many times as you wish to get
   # hard to guess binary randomness
   my $key1 = $prng->get (32);
   my $key2 = $prng->get (16);
   ...

   # for long running programs, it is advisable to
   # reseed the PRNG from time to time with new entropy
   $prng->add ($some_more_entropy);

=over 4

=item $prng = new Crypt::Spritz::PRNG [$seed]

Creates a new random number generator object. If C<$seed> is given, then
the C<$seed> is added to the internal state as if by a call to C<add>.

=item $prng->add ($entropy)

Adds entropy to the internal state, thereby hopefully making it harder
to guess. Good sources for entropy are irregular hardware events, or
randomness provided by C</dev/urandom> or C</dev/random>.

The design of the Spritz PRNG should make it strong against attacks where
the attacker controls all the entropy, so it should be safe to add entropy
from untrusted sources - more is better than less if you need a CSPRNG.

For use as PRNG, of course, this matters very little.

=item $octets = $prng->get ($length)

Generates and returns C<$length> random octets as a string.

=back


=head2 THE Crypt::Spritz::Hash CLASS

This implements the Spritz digest/hash algorithm. It works very similar to
other digest modules on CPAN, such as L<Digest::SHA3>.

Typical use for hashing:

   # create hasher object
   my $hasher = new Crypt::Spritz::Hash;

   # now feed data to be hashed into $hasher
   # in as few or many calls as required
   $hasher->add ("Some data");
   $hasher->add ("Some more");

   # extract the hash - the object is not usable afterwards
   my $digest = $hasher->finish (32);

=over 4

=item $hasher = new Crypt::Spritz::Hash

Creates a new hasher object.

=item $hasher->add ($data)

Adds data to be hashed into the hasher state. It doesn't matter whether
you pass your data in in one go or split it up, the hash will be the same.

=item $digest = $hasher->finish ($length)

Calculates a hash digest of the given length and return it. The object
cannot sensibly be used for further hashing afterwards.

Typical digest lengths are 16 and 32, corresponding to 128 and 256 bit
digests, respectively.

=item $another_hasher = $hasher->clone

Make an exact copy of the hasher state. This can be useful to generate
incremental hashes, for example.

Example: generate a hash for the data already fed into the hasher, by keeping
the original hasher for further C<add> calls and calling C<finish> on a C<clone>.

   my $intermediate_hash = $hasher->clone->finish;

Example: hash 64KiB of data, and generate a hash after every kilobyte that
is over the full data.

   my $hasher = new Crypt::Spritz::Hash;

   for (0..63) {
      my $kib = "x" x 1024; # whatever data

      $hasher->add ($kib);

      my $intermediate_hash = $hasher->clone->finish;
      ...
   }

These kind of intermediate hashes are sometimes used in communications
protocols to protect the integrity of the data incrementally, e.g. to
detect errors early, while still having a complete hash at the end of a
transfer.

=back


=head2 THE Crypt::Spritz::MAC CLASS

This implements the Spritz Message Authentication Code algorithm. It works
very similar to other digest modules on CPAN, such as L<Digest::SHA3>, but
implements an authenticated digest (like L<Digest::HMAC>).

I<Authenticated> means that, unlike L<Crypt::Spritz::Hash>, where
everybody can verify and recreate the hash value for some data, with a
MAC, knowledge of the (hopefully) secret key is required both to create
and to verify the digest.

Typical use for hashing is almost the same as with L<Crypt::Spritz::MAC>,
except a key (typically 16 or 32 octets) is provided to the constructor:

   # create hasher object
   my $hasher = new Crypt::Spritz::Mac $key;

   # now feed data to be hashed into $hasher
   # in as few or many calls as required
   $hasher->add ("Some data");
   $hasher->add ("Some more");

   # extract the mac - the object is not usable afterwards
   my $mac = $hasher->finish (32);

=over 4

=item $hasher = new Crypt::Spritz::MAC $key

Creates a new hasher object. The C<$key> can be of any length, but 16 and
32 (128 and 256 bit) are customary.

=item $hasher->add ($data)

Adds data to be hashed into the hasher state. It doesn't matter whether
you pass your data in in one go or split it up, the hash will be the same.

=item $mac = $hasher->finish ($length)

Calculates a message code of the given length and return it. The object
cannot sensibly be used for further hashing afterwards.

Typical digest lengths are 16 and 32, corresponding to 128 and 256 bit
digests, respectively.

=item $another_hasher = $hasher->clone

Make an exact copy of the hasher state. This can be useful to
generate incremental macs, for example.

See the description for the C<Crypt::Spritz::Hash::clone> method for some
examples.

=back


=head2 THE Crypt::Spritz::Cipher::XOR CLASS

This class implements stream encryption/decryption. It doesn't implement
the standard Spritz encryption but the XOR variant (called B<spritz-xor>
in the paper).

The XOR variant should be as secure as the standard variant, but
doesn't have separate encryption and decryaption functions, which saves
codesize. IT is not compatible with standard Spritz encryption, however -
drop me a note if you want that implemented as well.

Typical use for encryption I<and> decryption (code is identical for
decryption, you simply pass the encrypted data to C<crypt>):

   # create a cipher - $salt can be a random string you send
   # with your message, in clear, a counter (best), or empty if
   # you only want to encrypt one message with the given key.
   # 16 or 32 octets are typical sizes for the key, for the salt,
   # use whatever you need to give a unique salt for every
   # message you encrypt with the same key.

   my $cipher = Crypt::Spritz::Cipher::XOR $key, $salt;

   # encrypt a message in one or more calls to crypt

   my $encrypted;

   $encrypted .= $cipher->crypt ("This is");
   $encrypted .= $cipher->crypt ("all very");
   $encrypted .= $cipher->crypt ("secret");

   # that's all

=over 4

=item $cipher = new Crypt::Spritz::Cipher::XOR $key[, $iv]

Creates a new cipher object usable for encryption and decryption. The
C<$key> must be provided, the initial vector C<$IV> is optional.

Both C<$key> and C<$IV> can be of any length. Typical lengths for the
C<$key> are 16 (128 bit) or 32 (256 bit), while the C<$IV> simply needs to
be long enough to distinguish repeated uses of tghe same key.

=item $encrypted = $cipher->crypt ($cleartext)

=item $cleartext = $cipher->crypt ($encrypted)

Encrypt or decrypt a piece of a message. This can be called as many times
as you want, and the message can be split into as few or many pieces as
required without affecting the results.

=item $cipher->crypt_inplace ($cleartext_or_ciphertext)

Same as C<crypt>, except it I<modifies the argument in-place>.

=item $another_cipher = $cipher->clone

Make an exact copy of the cipher state. This can be useful to cache states
for reuse later, for example, to avoid expensive key setups.

While there might be use cases for this feature, it makes a lot more sense
for C<Crypt::Spritz::AEAD> and C<Crypt::Spritz::AEAD::XOR>, as they allow
you to specify the IV/nonce separately.

=item $constant_32 = $cipher->keysize

=item $constant_64 = $cipher->blocksize

These methods are provided for L<Crypt::CBC> compatibility and simply
return C<32> and C<64>, respectively.

Note that it is pointless to use Spritz with L<Crypt::CBC>, as Spritz is
not a block cipher and already provides an appropriate mode.

=back


=head2 THE Crypt::Spritz::Cipher CLASS

This class is pretty much the same as the C<Crypt::Spritz::Cipher::XOR>
class, with two differences: first, it implements the "standard" Spritz
encryption algorithm, and second, while this variant is easier to analyze
mathematically, there is little else to recommend it for, as it is slower,
and requires lots of code duplication code.

So unless you need to be compatible with another implementation that does
not offer the XOR variant, stick to C<Crypt::Spritz::Cipher::XOR>.

All the methods from C<Crypt::Spritz::Cipher::XOR> are available, except
C<crypt>, which has been replaced by separate C<encrypt> and C<decrypt>
methods:

=over 4

=item $encrypted = $cipher->encrypt ($cleartext)

=item $cleartext = $cipher->decrypt ($encrypted)

Really the same as C<Crypt::Spritz::Cipher::XOR>, except you need separate
calls and code for encryption and decryption.

=back


=head2 THE Crypt::Spritz::AEAD::XOR CLASS

This is the most complicated class - it combines encryption and
message authentication into a single "authenticated encryption
mode". It is similar to using both L<Crypt::Spritz::Cipher::XOR> and
L<Crypt::Spritz::MAC>, but makes it harder to make mistakes in combining
them.

You can additionally provide cleartext data that will not be encrypted or
decrypted, but that is nevertheless authenticated using the MAC, which
is why this mode is called I<AEAD>, I<Authenticated Encryption with
Associated Data>. Associated data is usually used to any header data that
is in cleartext, but should nevertheless be authenticated.

This implementation implements the XOR variant. Just as with
L<Crypt::Spritz::Cipher::XOR>, this means it is not compatible with
the standard mode, but uses less code and doesn't distinguish between
encryption and decryption.

Typical usage is as follows:

   # create a new aead object
   # you use one object per message
   # key length customarily is 16 or 32
   my $aead = new Crypt::Spritz::AEAD::XOR $key;

   # now you must feed the nonce. if you do not need a nonce,
   # you can provide the empty string, but you have to call it
   # after creating the object, before calling associated_data.
   # the nonce must be different for each usage of the $key.
   # a counter of some kind is good enough.
   # reusing a nonce with the same key completely
   # destroys security!
   $aead->nonce ($counter);

   # then you must feed any associated data you have. if you
   # do not have associated cleartext data, you can provide the empty
   # string, but you have to call it after nonce and before crypt.
   $aead->associated_data ($header);

   # next, you call crypt one or more times with your data
   # to be encrypted (opr decrypted).
   # all except the last call must use a length that is a
   # multiple of 64.
   # the last block can have any length.
   my $encrypted;

   $encrypted .= $aead->crypt ("1" x 64);
   $encrypted .= $aead->crypt ("2" x 64);
   $encrypted .= $aead->crypt ("3456");

   # finally you can calculate the MAC for all of the above
   my $mac = $aead->finish;

=over 4

=item $aead = new Crypt::Spritz::AEAD::XOR $key

Creates a new cipher object usable for encryption and decryption.

The C<$key> can be of any length. Typical lengths for the C<$key> are 16
(128 bit) or 32 (256 bit).

After creation, you have to call C<nonce> next.

=item $aead->nonce ($nonce)

Provide the nonce value (nonce means "value used once"), a value the is
unique between all uses with the same key. This method I<must> be called
I<after> C<new> and I<before> C<associated_data>.

If you only ever use a given key once, you can provide an empty nonce -
but you still have to call the method.

Common strategies to provide a nonce are to implement a persistent counter
or to generate a random string of sufficient length to guarantee that it
differs each time.

The problem with counters is that you might get confused and forget
increments, and thus reuse the same sequence number. The problem with
random strings i that your random number generator might be hosed and
generate the same randomness multiple times (randomness can be very hard
to get especially on embedded devices).

=item $aead->associated_data ($data)

Provide the associated data (cleartext data to be authenticated but not
encrypted). This method I<must> be called I<after> C<nonce> and I<before>
C<crypt>.

If you don't have any associated data, you can provide an empty string -
but you still have to call the method.

Associated data is typically header data - data anybody is allowed to
see in cleartext, but that should nevertheless be protected with an
authentication code. Typically such data is used to identify where to
forward a message to, how to find the key to decrypt the message or in
general how to interpret the encrypted part of a message.

=item $encrypted = $cipher->crypt ($cleartext)

=item $cleartext = $cipher->crypt ($encrypted)

Encrypt or decrypt a piece of a message. This can be called as many times
as you want, and the message can be split into as few or many pieces as
required without affecting the results, with one exception: All except the
last call to C<crypt> needs to pass in a multiple of C<64> octets. The
last call to C<crypt> does not have this limitation.

=item $cipher->crypt_inplace ($cleartext_or_ciphertext)

Same as C<crypt>, except it I<modifies the argument in-place>.

=item $another_cipher = $cipher->clone

Make an exact copy of the cipher state. This can be useful to cache states
for reuse later, for example, to avoid expensive key setups.

Example: set up a cipher state with a key, then clone and use it to
encrypt messages with different nonces.

   my $cipher = new Crypt::Spritz::AEAD::XOR $key;

   my $message_counter;

   for my $message ("a", "b", "c") {
      my $clone = $cipher->clone;
      $clone->nonce (pack "N", ++$message_counter);
      $clone->associated_data ("");
      my $encrypted = $clone->crypt ($message);
      ...
   }

=back


=head2 THE Crypt::Spritz::AEAD CLASS

This class is pretty much the same as the C<Crypt::Spritz::AEAD::XOR>
class, with two differences: first, it implements the "standard" Spritz
encryption algorithm, and second, while this variant is easier to analyze
mathematically, there is little else to recommend it for, as it is slower,
and requires lots of code duplication code.

So unless you need to be compatible with another implementation that does
not offer the XOR variant, stick to C<Crypt::Spritz::AEAD::XOR>.

All the methods from C<Crypt::Spritz::AEAD::XOR> are available, except
C<crypt>, which has been replaced by separate C<encrypt> and C<decrypt>
methods:

=over 4

=item $encrypted = $cipher->encrypt ($cleartext)

=item $cleartext = $cipher->decrypt ($encrypted)

Really the same as C<Crypt::Spritz::AEAD::XOR>, except you need separate
calls and code for encryption and decryption, but you have the same
limitations on usage.

=back


=head1 SECURITY CONSIDERATIONS

At the time of this writing, Spritz has not been through a lot of
cryptanalysis - it might get broken tomorrow. That's true for any crypto
algo, but the probability is quite a bit higher with Spritz. Having said
that, Spritz is almost certainly safer than RC4 at this time.

Nevertheless, I wouldn't protect something very expensive with it. I also
would be careful about timing attacks.

Regarding key lengths - as has been pointed out, traditional symmetric key
lengths (128 bit, 256 bit) work fine. Longer keys will be overkill, but
you can expect keys up to about a kilobit to be effective. Longer keys are
safe to use, they will simply be a waste of time.


=head1 PERFORMANCE

As a cipher/prng, Spritz is reasonably fast (about 100MB/s on 2014 era
hardware, for comparison, AES will be more like 200MB/s).

For key setup, ivs, hashing, nonces and so on, Spritz is very slow (about
5MB/s on 2014 era hardware, which does SHA-256 at about 200MB/s).


=head1 SUPPORT FOR THE PERL MULTICORE SPECIFICATION

This module supports the perl multicore specification
(L<http://perlmulticore.schmorp.de/>) for all encryption/decryption
(non-aead > 4000 octets, aead > 400 octets), hashing/absorbing (> 400
octets) and squeezing/prng (> 4000 octets) functions.


=head1 SEE ALSO

L<http://people.csail.mit.edu/rivest/pubs/RS14.pdf>.

=head1 SECURITY CONSIDERATIONS

I also cannot give any guarantees for security, Spritz is a very new
cryptographic algorithm, and when this module was written, almost
completely unproven.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/Crypt-Spritz

=cut

1;

