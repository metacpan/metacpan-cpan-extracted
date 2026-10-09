package Dancer2::Session::Pg::Cipher;

use strict;
use warnings;

use Moo::Role;
use Carp            qw( croak );
use Module::Runtime qw( use_module );

our $VERSION = '0.001';

requires qw( cipher_id cipher_name key_bytes iv_bytes tag_bytes seal unseal );

# A plugged-in cipher is security-critical code this module did not write, so a
# candidate is exercised once when the engine is built rather than trusted until
# somebody's first login. Three ways one fails here: it describes itself
# impossibly, it cannot read back what it wrote, or it accepts a payload that has
# been altered -- the last being the whole reason only AEAD modes are allowed.
sub cipher_self_check {    ## no critic (Subroutines::ProhibitExcessComplexity) -- one linear list of guards; splitting it to satisfy a metric would hide the sequence
    my ($self) = @_;

    # Called as both a class and an instance method, so take the name either way
    # without the `ref $x || $x` idiom, which reads as a typo to half of Perl.
    my $class = ref $self ? ref $self : $self;

    for my $method (qw( cipher_id key_bytes iv_bytes tag_bytes )) {
        my $value = $self->$method;
        croak sprintf '%s: %s must be a positive integer (got %s)', $class, $method, ( defined $value ? "'$value'" : 'undef' )
          if !defined $value || $value !~ m/\A[0-9]+\z/msx || $value < 1;    ## no critic (RegularExpressions::ProhibitEnumeratedClasses) -- [0-9] is ASCII-only; \d and [[:digit:]] both match Unicode digits
    }

    croak sprintf '%s: cipher_id must be in 1..255 (got %d)', $class, $self->cipher_id
      if $self->cipher_id > 255;

    my $name = $self->cipher_name;
    croak "$class: cipher_name must be a non-empty string"
      if !defined $name || !length $name;

    my $key   = 'K' x $self->key_bytes;
    my $iv    = 'N' x $self->iv_bytes;
    my $plain = 'Dancer2::Session::Pg cipher self check';
    my $aad   = 'session-id-one';

    my ( $ciphertext, $tag ) = $self->seal( $key, $iv, $plain, $aad );

    croak "$class: seal returned no ciphertext"
      if !defined $ciphertext || !length $ciphertext;
    croak sprintf '%s: seal returned a %d-byte tag but tag_bytes says %d', $class,
      ( defined $tag ? length $tag : 0 ), $self->tag_bytes
      if !defined $tag || length $tag != $self->tag_bytes;

    # THE ONE THING THE REST OF THIS CHECK WOULD MISS. Everything above and
    # below tests AUTHENTICATION -- that the tag is real, that altered input is
    # refused, that the additional data is bound in. A cipher that computes a
    # genuine MAC over the plaintext and then returns the plaintext as its
    # ciphertext passes every one of those, round trips perfectly, refuses
    # every forgery -- and writes sessions to the database IN THE CLEAR.
    #
    # That is not a hypothetical shape: it is what an encrypt-then-MAC wrapper
    # degrades into if the author returns the wrong variable, and the failure
    # is invisible from outside because every test of correctness still
    # passes. For a module whose only purpose is encryption at rest, not
    # checking that the cipher encrypts is the one omission that matters.
    croak "$class: seal returned the plaintext unchanged as its ciphertext, so every "
      . 'session would be stored in the clear. The tag may well be sound -- this is '
      . 'what an encrypt-then-MAC implementation looks like when it returns the '
      . 'plaintext instead of the encrypted bytes.'
      if $ciphertext eq $plain;

    my $back = eval { $self->unseal( $key, $iv, $ciphertext, $tag, $aad ) };
    croak "$class: unseal did not return what seal was given"
      if !defined $back || $back ne $plain;

    # The tag is the point, and the bar is ANY defined result rather than "not
    # the original plaintext". An unauthenticated stream mode hands back
    # *modified* plaintext for modified input, which is not a curiosity: it is
    # the attack. Flipping the bits under `"admin":0` to make it `"admin":1`
    # needs no key, and a session store that deserialises the result and then
    # trusts it has given the whole thing away. So a cipher that returns anything
    # at all for input it did not authenticate is refused here.
    for my $case ( [ 'ciphertext', 0 ], [ 'tag', 1 ] ) {
        my ( $part, $is_tag ) = @{$case};
        my @args = ( $ciphertext, $tag );
        my $i    = $is_tag ? 1 : 0;

        # 4-argument substr rather than the lvalue form, which Perl::Critic
        # dislikes and which reads worse here anyway.
        my $flipped = ( ord substr $args[$i], -1 ) ^ 0xFF;
        substr $args[$i], -1, 1, chr $flipped;

        my $forged = eval { $self->unseal( $key, $iv, @args, $aad ) };
        croak "$class: unseal returned data for a payload whose $part had been altered -- not an authenticated cipher"
          if defined $forged;
    }

    # LAST, because it is the narrower fault: a cipher that fails the checks
    # above does not authenticate at all, and saying so is more use than saying
    # it mishandled the additional data.
    #
    # A cipher that accepts the additional data and then ignores it is the
    # dangerous kind of wrong -- every round trip works, nothing looks amiss,
    # and the engine's binding of a payload to its session id silently does not
    # exist. That binding is what stops somebody with write access to the table
    # moving an administrator's sealed payload into their own row, so it is
    # tested rather than taken on trust.
    my $wrong_aad = eval { $self->unseal( $key, $iv, $ciphertext, $tag, 'session-id-two' ) };
    croak "$class: unseal IGNORED the additional authenticated data -- "
      . 'a payload sealed for one session id would open under another'
      if defined $wrong_aad;

    $self->_check_reserved_cipher_id( $key, $iv, $plain, $aad );

    return 1;
}

# WHAT CLAIMING A BUILT-IN ID PROMISES, enforced rather than documented.
#
# The id is one byte of every stored row and it is how a reader decides which
# cipher to hand a payload to. So a class claiming a built-in id is making a
# specific promise -- "I am that cipher, byte for byte" -- and the reason to
# allow it at all is the legitimate case: a different implementation of the same
# algorithm, hardware-accelerated or audited or vendored, that must read every
# row the original wrote.
#
# The accident is the common case, though. The documentation used to say "an
# integer in 1..255" and nothing else, so an author writing a genuinely new
# cipher would reasonably pick 1 -- and then every row AES-128-GCM had written
# became unreadable, with the header agreeing about the id and the tag failing.
# Prose does not stop that. A round trip does.
#
# Both directions, because both happen: the engine must read what the built-in
# wrote before the swap, and the built-in must read what the claimant wrote if it
# is ever removed. A cipher that passes only one way is not a drop-in.
# The core reserves 1..127; 128..255 belongs to whoever deploys a cipher of
# their own, where a collision is theirs to manage.
use constant CORE_ID_MAX => 128;

my %CORE_CIPHER_FOR_ID = (
    1 => [ 'Dancer2::Session::Pg::Cipher::AESGCM', key_bytes => 16 ],
    2 => [ 'Dancer2::Session::Pg::Cipher::AESGCM', key_bytes => 24 ],
    3 => [ 'Dancer2::Session::Pg::Cipher::AESGCM', key_bytes => 32 ],
    4 => ['Dancer2::Session::Pg::Cipher::ChaCha20Poly1305'],
);

sub _check_reserved_cipher_id {
    my ( $self, $key, $iv, $plain, $aad ) = @_;

    my $class = ref $self ? ref $self : $self;
    my $id    = $self->cipher_id;
    my $spec  = $CORE_CIPHER_FOR_ID{$id};

    # 5..127 is reserved for built-ins that do not exist yet. Refusing it is the
    # point: a third-party cipher that takes id 5 today works perfectly until
    # this distribution ships a built-in with that id, and then two different
    # formats share one header byte and the older rows become unreadable. There
    # is no interop check to offer, because there is nothing yet to interop
    # with -- so the only safe answer is no.
    croak sprintf '%s: cipher_id %d is in the range 1..127, which this distribution '
      . 'reserves for its own ciphers -- %d is not in use yet, and claiming it now '
      . 'would collide with a future built-in and make these rows unreadable. '
      . 'Pick an unused id in 128..255', $class, $id, $id
      if !$spec && $id < CORE_ID_MAX;

    return 1 if !$spec;                   # 128..255: the third-party range
    my ( $core_class, @core_args ) = @{$spec};
    return 1 if $class eq $core_class;    # the built-in itself

    my $core = use_module($core_class)->new(@core_args);

    # Declared lengths first: a mismatch here is the same fault with a clearer
    # name than a round trip that merely fails.
    for my $method (qw( key_bytes iv_bytes tag_bytes )) {
        next if $self->$method == $core->$method;
        croak sprintf '%s: cipher_id %d is %s, whose %s is %d, but this cipher says %d. '
          . 'An id identifies one stored format; pick an unused id in 128..255 instead',
          $class, $id, $core->cipher_name, $method, $core->$method, $self->$method;
    }

    my $fail =
        sprintf '%s: cipher_id %d belongs to %s, and claiming it means being able to '
      . 'read and write that cipher\'s rows byte for byte. This cipher cannot (%%s). '
      . 'If it is a NEW cipher rather than a replacement, pick an unused id in 128..255',
      $class, $id, $core->cipher_name;

    my ( $core_ct, $core_tag ) = $core->seal( $key, $iv, $plain, $aad );
    my $read = eval { $self->unseal( $key, $iv, $core_ct, $core_tag, $aad ) };
    croak sprintf $fail, 'it cannot read what ' . $core->cipher_name . ' wrote'
      if !defined $read || $read ne $plain;

    my ( $own_ct, $own_tag ) = $self->seal( $key, $iv, $plain, $aad );
    my $back = eval { $core->unseal( $key, $iv, $own_ct, $own_tag, $aad ) };
    croak sprintf $fail, $core->cipher_name . ' cannot read what it wrote'
      if !defined $back || $back ne $plain;

    return 1;
}

1;

__END__

=encoding utf8

=for stopwords AEAD AES ChaCha DDL DSN GCM Kubernetes NIST OpenID Poly XHR crashloops dbh dbpass dbschema dbtable dbuser decrypt decryptable decrypted decrypts deserialise deserialising diagnosable dsn encryptions nonces plaintext preforked rollout serialiser tablespace Koivunalho Mikko vendored

=head1 NAME

Dancer2::Session::Pg::Cipher - the authenticated-cipher contract for Dancer2::Session::Pg

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package My::Cipher::XChaCha20;

    use Moo;
    with 'Dancer2::Session::Pg::Cipher';

    use Crypt::AuthEnc::ChaCha20Poly1305 ();

    sub cipher_id   { return 200 }            # third-party range: 128..255
    sub cipher_name { return 'XChaCha20-Poly1305' }
    sub key_bytes   { return 32 }
    sub iv_bytes    { return 24 }             # a 24-byte nonce, unlike the core four
    sub tag_bytes   { return 16 }

    # $aad is authenticated but NOT encrypted, and must not be dropped: it is
    # what binds a sealed payload to the session id it belongs to.
    sub seal {
        my ( $self, $key, $iv, $plaintext, $aad ) = @_;
        return My::XChaCha::seal( $key, $iv, $aad, $plaintext );    # ( $ciphertext, $tag )
    }

    sub unseal {
        my ( $self, $key, $iv, $ciphertext, $tag, $aad ) = @_;
        return My::XChaCha::open( $key, $iv, $aad, $ciphertext, $tag );  # $plaintext or undef
    }

    # and then, in the application, as the alg of a slot
    #   encryption_keys:
    #     0: { key: "...", alg: "AES-256-GCM" }          # kept, read only
    #     1:
    #       key:    "..."
    #       alg:    "My::Cipher::XChaCha20"
    #       active: true

=head1 DESCRIPTION

L<Dancer2::Session::Pg> stores a cipher identifier in every payload it writes, so
the cipher a session was written with is a property of the row rather than of the
configuration. That is what makes a cipher replaceable: point C<alg> at a new one
and new sessions use it while existing rows stay readable until they expire.

This role is the contract such a cipher implements. Consume it with C<with>
rather than duck-typing the methods: that is how L</cipher_self_check> arrives,
and the engine refuses a cipher that does not provide it.

=head2 Only authenticated modes

A session frequently carries the credentials that prove who somebody is. A row
that has been altered in the database must B<fail to decrypt>, not deserialise
into a structure the application then trusts, so every cipher here produces a
tag and verifies it. L</cipher_self_check> tests exactly that, by flipping a bit
and insisting the result is refused.

=head2 Cipher ids are permanent

The id is one byte in every stored payload. Changing a cipher's id makes rows
written under the old one unreadable, which logs those users out.

    1 .. 127      reserved for ciphers shipped with Dancer2::Session::Pg
    128 .. 255    third-party range

The engine croaks at construction if two readable ciphers claim one id, so a
collision is a startup failure rather than a payload that decrypts as the wrong
thing. Within the third-party range a deployment owns its own collisions.

=head2 Your key length is your own business

A cipher declares the C<key_bytes> it needs, and the engine checks the key of the
slot your cipher sits in against B<that cipher and nothing else>. Other slots may
hold keys of other lengths; it does not concern you.

So there is no equal-key-length restriction to design around. A deployment can
rotate from a 16-byte cipher to a 32-byte one in a single step by giving the new
pair a slot of its own, which is what L<Dancer2::Session::Pg/Changing the key
length> describes and what the distribution's own test suite exercises.

What you must not do is assume anything about the key beyond its length. One
engine may hold several keys, a given row names the slot that sealed it, and your
C<seal> and C<unseal> are handed the key for that slot and never asked to choose.

=head1 REQUIRED METHODS

=head2 cipher_id

An integer in C<1 .. 255>, written into every payload. Permanent; see above.

B<Four are already taken>, and they are part of the stored format, so they are
not available for reuse:

    1    AES-128-GCM            (Dancer2::Session::Pg::Cipher::AESGCM, 16-byte key)
    2    AES-192-GCM            (the same class, 24-byte key)
    3    AES-256-GCM            (the same class, 32-byte key)
    4    ChaCha20-Poly1305      (Dancer2::Session::Pg::Cipher::ChaCha20Poly1305)

B<Pick from C<128 .. 255> for a cipher of your own.> C<1 .. 127> is reserved
for built-ins, used or not, and L</cipher_self_check> refuses an id in that
range that no built-in has yet taken -- claiming one would work perfectly today
and collide with a future built-in, at which point the rows written under it
become unreadable.

Claiming one of the four ON PURPOSE is a legitimate thing to do -- a
hardware-accelerated, audited or vendored implementation of the same algorithm
has to keep the id, or it could not read the rows it is replacing. But it means
exactly one thing, B<this class is a byte-compatible drop-in for that cipher>,
and L</cipher_self_check> B<enforces it> rather than trusting it: a class
claiming a reserved id must read a payload the built-in wrote, and the built-in
must read one it wrote. Both directions, because both happen -- the engine reads
old rows after the swap, and the built-in reads the replacement's rows if it is
ever taken out again.

So a NEW cipher that takes a reserved id is refused at construction, with the
range to use instead. Without that check it would have worked perfectly on an
empty table and then failed to open a single row written before it, the stored
header agreeing about the cipher and the tag disagreeing about everything else.

Two ciphers colliding inside C<128 .. 255> are a separate matter, and the engine
refuses that ring too -- but only when both are configured at once, which is all
it can see.

=head2 cipher_name

A short string for error messages and C<algorithms>. Not stored.

=head2 key_bytes, iv_bytes, tag_bytes

The exact lengths this cipher requires, as integers. The engine validates the
configured key against C<key_bytes>, draws C<iv_bytes> from
L<Crypt::PRNG|CryptX> for every write, and uses C<tag_bytes> to find the
boundaries when reading a row back, so all three must be constant for a given
C<cipher_id>.

=head2 It must actually encrypt

L</cipher_self_check> compares the ciphertext against the plaintext and refuses
a cipher that returns the plaintext unchanged.

This is worth stating because every other check in that method tests
B<authentication>: that the tag is real, that altered input is refused, that the
additional data is bound in. A cipher that computes a sound MAC over the
plaintext and then hands back the plaintext as its ciphertext passes all of
them. It round trips, it refuses every forgery -- and it writes sessions to the
database in the clear.

That is not a contrived shape. It is what an encrypt-then-MAC implementation
becomes if its author returns the wrong variable, and nothing about the result
looks wrong from outside.

=head2 seal

    my ( $ciphertext, $tag ) = $cipher->seal( $key, $iv, $plaintext, $aad );

Encrypts and authenticates. Must return the tag separately, and it must be
exactly C<tag_bytes> long.

C<$aad> is additional data that must be B<authenticated but not encrypted>. The
engine passes the payload header and the session id, which is what binds a
sealed session to the row it belongs to. Pass it to your AEAD primitive -- do not
drop it, and do not encrypt it.

=head2 unseal

    my $plaintext = $cipher->unseal( $key, $iv, $ciphertext, $tag, $aad );

Verifies and decrypts. On failure, return C<undef> or throw -- the engine treats
both as "this row is not readable" and the session then looks absent rather than
corrupt. Do not return unverified plaintext under any circumstances, and B<fail
when C<$aad> does not match> what C<seal> was given: a cipher that accepts the
additional data and then ignores it would let a payload sealed for one session id
open under another. L</cipher_self_check> tests exactly that.

=head1 PROVIDED METHODS

=head2 cipher_self_check

    $cipher->cipher_self_check;    # or croaks

Called by L<Dancer2::Session::Pg> when the engine is built, once for B<every>
configured slot's cipher -- including the retired ones kept only to read old
rows, since a cipher that cannot be trusted to read is no more use than one that
cannot be trusted to write. Checks that the declared lengths are plausible, that
a known plaintext survives a round trip, that the tag is the advertised length,
that altering either the ciphertext or the tag is refused, and that the
additional authenticated data is actually authenticated.

It costs microseconds per slot and it runs before the process serves anything.

=head1 SEE ALSO

=over 4

=item * L<Dancer2::Session::Pg>

=item * L<Dancer2::Session::Pg::Cipher::AESGCM>

=item * L<Dancer2::Session::Pg::Cipher::ChaCha20Poly1305>

=back

=head1 AUTHOR

Mikko Koivunalho <mikko.koivunalho@iki.fi>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
