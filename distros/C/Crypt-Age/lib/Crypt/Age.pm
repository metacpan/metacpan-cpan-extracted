package Crypt::Age;
# ABSTRACT: Perl implementation of age encryption (age-encryption.org)

use Moo;
use Carp qw(croak);
use Crypt::Age::Keys;
use Crypt::Age::Primitives;
use Crypt::Age::Header;
use namespace::clean;


our $VERSION = '0.004';

sub generate_keypair {
    my ($class) = @_;
    return Crypt::Age::Keys->generate_keypair;
}


sub encrypt {
    my ($class, %args) = @_;

    my $plaintext  = $args{plaintext}  // croak "plaintext required";
    my $recipients = $args{recipients} // croak "recipients required";

    # This is perl's own test for the in-memory open below, hoisted so it can
    # say what is wrong. PerlIO::scalar downgrades the string in place
    # (sv_utf8_downgrade) and, when that cannot be done, warns "Strings with
    # code points over 0xFF may not be mapped into in-memory file handles" and
    # returns EINVAL -- so the open croaked "open on input string: Invalid
    # argument", which tells a caller who passed decoded characters nothing at
    # all. Running the test first replaces that with a message naming the
    # cause, and the warning never happens because the open is never reached.
    #
    # Not utf8::is_utf8: it reports the internal representation, so a pure
    # ASCII string that happens to be stored upgraded answers true while
    # holding nothing above 0xFF. What decides this is the content.
    #
    # Not a /[^\x00-\xff]/ scan either, though both are free on an unflagged
    # string (perl short-circuits: downgrade on the flag, the regex on the
    # optimizer knowing that class cannot match a non-UTF-8 target -- measured
    # at 2000 passes over 16 MiB in under 0.01s CPU for both). They part on a
    # flagged string: over 16 MiB, downgrade costs 32ms against the regex's
    # 55ms, and it *is* the scan perl is about to do, so it leaves the string
    # downgraded and perl's repeat of it is then a flag test. The regex pays
    # for that scan twice. Worth it either way, but this way costs least.
    #
    # Mutating our own copy is safe and changes nothing a caller can see:
    # downgrading converts the representation, never the value, %args and the
    # lexical are both copies, and on success perl's open performs this very
    # conversion anyway. A failure leaves the string untouched.
    #
    # One bit comes back, which is all that may be reported anyway: the offset
    # a scan would yield is derived from the caller's plaintext, and plaintext
    # does not go into error messages.
    utf8::downgrade($plaintext, 1)
        or croak 'plaintext must be a byte string: it holds a code point '
            .'above 0xFF, encode it before passing it in';

    open my $ifh, '<:raw', \$plaintext or croak "open on input string: $!";

    my $output = '';
    open my $ofh, '>:raw', \$output or croak "open on output string: $!";

    $class->_encrypt_fh($ifh, $ofh, $recipients);

    return $output;
}


sub decrypt {
    my ($class, %args) = @_;

    my $ciphertext = $args{ciphertext} // croak "ciphertext required";
    my $identities = $args{identities} // croak "identities required";

    # Same test, same reasons as in encrypt above; the advice differs because
    # age ciphertext is binary, so a wide character in it means the caller
    # decoded bytes that were never text rather than forgot to encode text.
    utf8::downgrade($ciphertext, 1)
        or croak 'ciphertext must be a byte string: it holds a code point '
            .'above 0xFF, read it with :raw rather than decoding it';

    open my $ifh, '<:raw', \$ciphertext or croak "open on input string: $!";

    my $output = '';
    open my $ofh, '>:raw', \$output or croak "open on output string: $!";

    # Forwarded only when the caller actually gave it, so that "not passed"
    # stays distinguishable from "passed as undef" all the way down: the first
    # takes Header's default, the second is an error there. Building the pair
    # here rather than defaulting it means this method names no limit of its
    # own -- see Crypt::Age::Header/THE STANZA LIMIT for the number and why it
    # is ours rather than the format's.
    $class->_decrypt_fh($ifh, $ofh, $identities,
        exists $args{max_stanzas} ? ( max_stanzas => $args{max_stanzas} ) : ());

    return $output;
}


sub _encrypt_fh {
    my ($class, $ifh, $ofh, $recipients) = @_;
    binmode($ifh, ':raw') or croak "cannot binmode input filehandle: $!";
    binmode($ofh, ':raw') or croak "cannot binmode output filehandle: $!";

    # Same skeleton as the shape checks in Crypt::Age::Header -- <param> must
    # be a <Type>, then a clause carrying the requirement and its reason, then
    # the fix -- because this guard and Header::create's fire on the identical
    # caller mistake and only differ in which layer catches it first. This one
    # always does: create is called below with the list this already accepted,
    # so its message is unreachable from here and a caller who searched for
    # one wording had to find the other.
    #
    # The reason is this layer's, not create's: create wraps the file key once
    # per entry, while what a caller of encrypt sees is that every entry ends
    # up able to decrypt. Nothing is interpolated, for the reason written out
    # at create -- the mistake that puts a bare string here is the swap of
    # recipient and identity, so the value is not reliably a public one.
    croak 'recipients must be an ArrayRef: this method encrypts to every '
        .'entry, pass [$recipient] rather than $recipient'
        if ref($recipients) ne 'ARRAY';
    # The emptiness case, moved onto the same skeleton in the same change that
    # gave Header::create a guard of its own. Leaving it on its old wording
    # would have rebuilt, for the empty list, exactly the divergence the shape
    # checks above were just brought out of. The reason is this layer's again:
    # what a caller of encrypt sees is not a header without stanzas but a
    # result nobody can open.
    croak 'recipients must not be empty: this method encrypts to every entry, '
        .'so with none the result can never be decrypted, pass at least one '
        .'recipient'
        unless @$recipients;

    # Generate random file key
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    # Create header with wrapped file key for each recipient
    print {$ofh} Crypt::Age::Header->create($file_key, $recipients)->to_string;

    # Generate payload nonce and derive payload key
    my $nonce = Crypt::Age::Primitives->generate_payload_nonce;
    print {$ofh} $nonce;

    my $payload_key = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);
    return Crypt::Age::Primitives->encrypt_payload_fh($payload_key, $ifh, $ofh);
}

sub encrypt_file {
    my ($class, %args) = @_;
    my $input      = $args{input}      // croak "input required";
    my $output     = $args{output}     // croak "output required";
    my $recipients = $args{recipients} // croak "recipients required";

    open my $in_fh, '<:raw', $input
        or croak "Cannot open input file '$input': $!";
    open my $out_fh, '>:raw', $output
        or croak "Cannot open output file '$output': $!";

    $class->_encrypt_fh($in_fh, $out_fh, $recipients);

    close $out_fh or croak "Cannot close output file '$output': $!";
    close $in_fh  or croak "Cannot close input file '$input': $!";

    return 1;
}


sub encrypt_filehandle {
    my ($class, %args) = @_;
    my $in_fh      = $args{input}      // croak "input required";
    my $out_fh     = $args{output}     // croak "output required";
    my $recipients = $args{recipients} // croak "recipients required";

    $class->_encrypt_fh($in_fh, $out_fh, $recipients);

    return 1;

}


sub _decrypt_fh {
    my ($class, $ifh, $ofh, $identities, %opt) = @_;
    binmode($ifh, ':raw') or croak "cannot binmode input filehandle: $!";
    binmode($ofh, ':raw') or croak "cannot binmode output filehandle: $!";

    # The counterpart to the recipients check in _encrypt_fh, in the same form
    # and ahead of unwrap_file_key's own check for the same reason. The clause
    # is this layer's: unwrap_file_key tries each entry against each stanza,
    # while what a caller of decrypt sees is that the file opens if any one
    # entry fits.
    #
    # Never interpolate $identities. A bare string in this parameter is an
    # identity, and this croak stands between it and the dereference in
    # unwrap_file_key that would otherwise put 32 characters of secret key
    # material into an exception; a message quoting it here would reintroduce
    # exactly that leak one frame earlier.
    croak 'identities must be an ArrayRef: this method decrypts with '
        .'whichever entry matches, pass [$identity] rather than $identity'
        if ref($identities) ne 'ARRAY';
    # The counterpart, in the same form and moved in the same change. Unlike
    # the recipients side this one closes no defect: unwrap_file_key already
    # croaks "No matching identity found" for an empty list -- measured, not
    # assumed -- so nothing was ever silently accepted here. It moves so that
    # the empty list reads one way on both sides of the API.
    croak 'identities must not be empty: this method decrypts with whichever '
        .'entry matches, so with none there is nothing that could match, '
        .'pass at least one identity'
        unless @$identities;

    # Parse header. %opt carries max_stanzas when the caller passed one, and is
    # empty when they did not -- the default lives in Header, in one place, so
    # this layer never has to name a number. Validation is Header's too: unlike
    # identities above, a bad max_stanzas cannot leak anything and has one
    # meaning on both layers, so a second check here would only be a second
    # message to keep in step.
    my $header = Crypt::Age::Header->parse_from_fh($ifh, %opt);

    # Unwrap file key using identities
    my $file_key = $header->unwrap_file_key($identities);

    # Extract nonce (first 16 bytes after header) and encrypted payload
    my $nonce = Crypt::Age::Primitives->paranoid_read($ifh, 16);
    croak 'end of file reached before getting nonce' if length($nonce) != 16;

    # Derive payload key using nonce
    my $payload_key = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);

    return Crypt::Age::Primitives->decrypt_payload_fh($payload_key, $ifh, $ofh);
}

sub decrypt_file {
    my ($class, %args) = @_;
    my $input      = $args{input}      // croak "input required";
    my $output     = $args{output}     // croak "output required";
    my $identities = $args{identities} // croak "identities required";

    open my $in_fh, '<:raw', $input
        or croak "Cannot open input file '$input': $!";
    open my $out_fh, '>:raw', $output
        or croak "Cannot open output file '$output': $!";

    # As in decrypt above: forwarded only when given.
    $class->_decrypt_fh($in_fh, $out_fh, $identities,
        exists $args{max_stanzas} ? ( max_stanzas => $args{max_stanzas} ) : ());

    close $out_fh or croak "Cannot close output file '$output': $!";
    close $in_fh  or croak "Cannot close input file '$input': $!";

    return 1;
}


sub decrypt_filehandle {
    my ($class, %args) = @_;
    my $in_fh      = $args{input}      // croak "input required";
    my $out_fh     = $args{output}     // croak "output required";
    my $identities = $args{identities} // croak "identities required";

    # As in decrypt above: forwarded only when given.
    $class->_decrypt_fh($in_fh, $out_fh, $identities,
        exists $args{max_stanzas} ? ( max_stanzas => $args{max_stanzas} ) : ());

    return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Age - Perl implementation of age encryption (age-encryption.org)

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Crypt::Age;

    # Generate keypair
    my ($public, $secret) = Crypt::Age->generate_keypair();
    # $public  = "age19ljhmg68..."
    # $secret  = "AGE-SECRET-KEY-1..."

    # Encrypt data
    my $encrypted = Crypt::Age->encrypt(
        plaintext  => "Hello, World!",
        recipients => [$public],
    );

    # Decrypt data
    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    # Encrypt file
    Crypt::Age->encrypt_file(
        input      => 'secret.txt',
        output     => 'secret.txt.age',
        recipients => [$public],
    );

    # Decrypt file
    Crypt::Age->decrypt_file(
        input      => 'secret.txt.age',
        output     => 'secret.txt',
        identities => [$secret],
    );

=head1 DESCRIPTION

Crypt::Age is a pure Perl implementation of the age encryption format,
compatible with the reference Go implementation (L<https://github.com/FiloSottile/age>)
and the Rust implementation (L<https://github.com/str4d/rage>).

age is a simple, modern and secure file encryption tool with small explicit
keys, no config options, and UNIX-style composability. The format specification
is available at L<https://github.com/C2SP/C2SP/blob/main/age.md>.

This implementation uses X25519 for key exchange, ChaCha20-Poly1305 for
authenticated encryption, and HKDF-SHA256 for key derivation. All cryptographic
primitives are provided by L<CryptX>.

Files encrypted with Crypt::Age can be decrypted with the C<age> and C<rage>
command-line tools, and vice versa.

Two APIs are provided, and they differ in memory use. L</encrypt> and
L</decrypt> take and return in-memory strings, so the whole plaintext or
ciphertext has to fit in memory at once, both as the argument and as the
returned value. L</encrypt_file>, L</decrypt_file>, L</encrypt_filehandle> and
L</decrypt_filehandle> stream instead: they read and write in 64 KiB chunks, so
memory use stays bounded regardless of how large the file is.

Every method here is byte-oriented: it encrypts and decrypts octets, never
characters. The string API takes and returns byte strings; the file and
filehandle API forces C<:raw> on every handle it touches, which removes an
C<:encoding> layer the caller may have set on one. So encode a character
string -- anything that has been through C<Encode::decode> or arrived through
an C<:encoding> layer -- before you hand it over. L</encrypt> and L</decrypt>
reject one outright when they can tell.

See L</LIMITATIONS> below for what this module does not implement.

=head2 generate_keypair

    my ($public_key, $secret_key) = Crypt::Age->generate_keypair();

Generates a new X25519 keypair for age encryption.

Returns a list of two elements:

=over 4

=item * C<$public_key> - Bech32-encoded public key starting with C<age1>

=item * C<$secret_key> - Bech32-encoded secret key starting with C<AGE-SECRET-KEY-1>

=back

The public key can be shared with others to encrypt files for you. The secret
key must be kept private and is used to decrypt files encrypted to your public key.

=head2 encrypt

    my $ciphertext = Crypt::Age->encrypt(
        plaintext  => $data,
        recipients => \@public_keys,
    );

Encrypts plaintext data for one or more recipients.

Parameters:

=over 4

=item * C<plaintext> - The data to encrypt (required)

=item * C<recipients> - ArrayRef of Bech32-encoded public keys (required)

=back

Returns the encrypted data in age format, which includes a text header followed
by the encrypted payload. The file key is wrapped separately for each recipient,
allowing any of them to decrypt the data.

C<recipients> must really be an ArrayRef; a single recipient still goes in a
list of one. Every other shape is refused before the file key is generated,
with C<"recipients must be an ArrayRef: this method encrypts to every entry,
pass [$recipient] rather than $recipient">. As elsewhere in this distribution
the clause after the colon carries the requirement and its reason rather than a
description of what arrived, and quotes no part of the argument.

It must also be non-empty, and is refused with C<"recipients must not be
empty: this method encrypts to every entry, so with none the result can never
be decrypted, pass at least one recipient">. That message replaces the older
C<"at least one recipient required">; the check itself is unchanged and has
always been there. Encrypting to nobody produces a file whose file key is
wrapped for no one and therefore lost with the plaintext, and the age header
grammar requires at least one recipient stanza in any case.

The returned data can be written to a file or transmitted directly.

C<plaintext> and the returned ciphertext are both held in memory in full. For
large data, use L</encrypt_file> or L</encrypt_filehandle>, which stream in 64
KiB chunks instead.

C<plaintext> must be a B<byte string>. Encode a character string first:

    use Encode qw( encode );

    my $ciphertext = Crypt::Age->encrypt(
        plaintext  => encode('UTF-8', $characters),
        recipients => \@public_keys,
    );

A C<plaintext> holding a code point above C<0xFF> cannot be encrypted at all
and is rejected before anything else happens, with C<"plaintext must be a byte
string: it holds a code point above 0xFF, encode it before passing it in">.

A character string whose code points all happen to fit in a byte is B<not>
caught, because nothing distinguishes it from bytes: it is encrypted as those
bytes, which is Latin-1, and L</decrypt> hands Latin-1 back. Encoding
explicitly is the only way to decide which bytes get encrypted.

=head2 decrypt

    my $plaintext = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => \@secret_keys,
    );

Decrypts age-encrypted data using one or more identities.

Parameters:

=over 4

=item * C<ciphertext> - The age-encrypted data (required)

=item * C<identities> - ArrayRef of Bech32-encoded secret keys (required)

=item * C<max_stanzas> - Maximum number of recipient stanzas the header may
carry (optional, C<128> by default)

=back

Returns the decrypted plaintext.

C<identities> must really be an ArrayRef; a single identity still goes in a
list of one -- the likeliest way to get this wrong, since one identity does not
look like a list. Every other shape is refused before the header is parsed,
with C<"identities must be an ArrayRef: this method decrypts with whichever
entry matches, pass [$identity] rather than $identity">, which quotes no byte
of the argument: a bare string in this parameter is a secret key.

It must also be non-empty, and is refused with C<"identities must not be
empty: this method decrypts with whichever entry matches, so with none there is
nothing that could match, pass at least one identity">. That message replaces
the older C<"at least one identity required">, so that an empty list reads the
same way on both sides of the API; the check itself is unchanged.

The method tries each identity against each recipient stanza in the header until
one successfully unwraps the file key. Dies on the same conditions as
L</decrypt_file>, except file I/O errors -- this method never opens a file. It
also rejects a C<ciphertext> holding a code point above C<0xFF> before
attempting any of that; see below for the exact message.

Because that work is identities times stanzas and has to happen before any of
the header can be authenticated, a header is refused when it carries more than
C<max_stanzas> recipient stanzas -- C<128> by default. The limit is this
distribution's rather than the age format's, and is high enough for any file
this API produces but low enough to reject some that C<age -R> can write, so
raise it when you have such a file. C<max_stanzas> is accepted by this method,
L</decrypt_file> and L</decrypt_filehandle> alike, must be a positive integer,
and is documented in full under L<Crypt::Age::Header/THE STANZA LIMIT>.

C<ciphertext> must be a B<byte string>, and so is the plaintext this method
returns. age ciphertext is binary, so read it with C<:raw> and never through
an C<:encoding> layer; decode the returned plaintext yourself if the message
was text. A C<ciphertext> holding a code point above C<0xFF> is rejected
before anything else happens, with C<"ciphertext must be a byte string: it
holds a code point above 0xFF, read it with :raw rather than decoding it">.

C<ciphertext> and the returned plaintext are both held in memory in full. For
large data, use L</decrypt_file> or L</decrypt_filehandle>, which stream in 64
KiB chunks instead. Because this method never returns a value on failure, a
decryption that dies here does not expose any partial plaintext to the caller
-- contrast L</decrypt_filehandle>, which writes to a caller-supplied handle
and so can leave an authenticated-but-incomplete prefix behind.

=head2 encrypt_file

    Crypt::Age->encrypt_file(
        input      => 'plaintext.txt',
        output     => 'encrypted.age',
        recipients => \@public_keys,
    );

Encrypts a file for one or more recipients.

Parameters:

=over 4

=item * C<input> - Path to input file (required)

=item * C<output> - Path to output file (required)

=item * C<recipients> - ArrayRef of Bech32-encoded public keys (required)

=back

The output file will be in age format and can be decrypted with the C<age> or
C<rage> command-line tools.

Returns C<1> on success. Dies if a required argument is missing, if
C<recipients> is not a non-empty ArrayRef -- L</encrypt> quotes the two
messages, one for the shape and one for the empty list -- if a recipient
string is not a valid Bech32 C<age1...> public key, if C<binmode> fails on
either handle, or on file I/O errors.
Reads and writes the file in 64 KiB chunks, so memory use does not grow with
the size of the file.

=head2 encrypt_filehandle

    Crypt::Age->encrypt_filehandle(
        input      => \*STDIN,
        output     => \*STDOUT,
        recipients => \@public_keys,
    );

Encrypts for one or more recipients, based on filehandles for both input and
output.

Parameters:

=over 4

=item * C<input> - Input filehandle (required)

=item * C<output> - Output filehandle (required)

=item * C<recipients> - ArrayRef of Bech32-encoded public keys (required)

=back

Both filehandles will be forced to be C<:raw> using C<binmode>. That removes
every layer the caller had set, C<:encoding> included, so what is encrypted is
the bytes in C<input> and never characters decoded from them. This method
therefore needs no byte-string check of its own, unlike L</encrypt>: a handle
delivers octets by the time it is read from here.

The output stream will be in age format and can be decrypted with the C<age> or
C<rage> command-line tools.

Returns C<1> on success. Dies if a required argument is missing, if
C<recipients> is not a non-empty ArrayRef -- L</encrypt> quotes the two
messages, one for the shape and one for the empty list -- if a recipient string
is not a valid Bech32 C<age1...> public key, or if C<binmode> fails on either
handle. Unlike L</encrypt_file>, this method never opens or closes a file
itself -- C<input> and C<output> are handles the caller already has open -- so
it cannot die with a "file not found" or "permission denied" error; that is the
caller's concern before the handle is passed in. Streams in 64 KiB chunks, so
memory use does not grow with the amount of data written.

=head2 decrypt_file

    Crypt::Age->decrypt_file(
        input      => 'encrypted.age',
        output     => 'plaintext.txt',
        identities => \@secret_keys,
    );

Decrypts an age-encrypted file using one or more identities.

Parameters:

=over 4

=item * C<input> - Path to encrypted input file (required)

=item * C<output> - Path to decrypted output file (required)

=item * C<identities> - ArrayRef of Bech32-encoded secret keys (required)

=item * C<max_stanzas> - Maximum number of recipient stanzas the header may
carry (optional, C<128> by default)

=back

Returns C<1> on success. Dies if a required argument is missing, if
C<identities> is not a non-empty ArrayRef -- L</decrypt> quotes the two
messages, one for the shape and one for the empty list -- if the header is
invalid, if it carries more than C<max_stanzas> recipient stanzas (or if
C<max_stanzas> itself is not a positive integer), if no identity matches any
stanza, if the MAC verification fails, if payload authentication fails, if
C<binmode> fails on either handle, or on file I/O errors.

Reads the input and writes the output in 64 KiB chunks, so memory use does not
grow with the size of the file. B<This means a failure does not undo what was
already written>: every chunk that authenticated before the error is already
in C<output> on disk once this method dies. Each such chunk is individually
authentic, but the file as a whole is not -- that is exactly what the error
reports. Treat a partial C<output> as undecrypted and discard it; do not rely
on the bytes that made it out. See L<Crypt::Age::Primitives/decrypt_payload_fh>
for the same guarantee stated at the primitive layer.

=head2 decrypt_filehandle

    Crypt::Age->decrypt_filehandle(
        input      => \*STDIN,
        output     => \*STDOUT,
        identities => \@secret_keys,
    );

Decrypts age-encrypted data from a filehandle using one or more identities.
Output is sent to a filehandle too.

Parameters:

=over 4

=item * C<input> - Encrypted input filehandle (required)

=item * C<output> - Decrypted output filehandle (required)

=item * C<identities> - ArrayRef of Bech32-encoded secret keys (required)

=item * C<max_stanzas> - Maximum number of recipient stanzas the header may
carry (optional, C<128> by default)

=back

Both filehandles will be forced to be C<:raw> using C<binmode>. That removes
every layer the caller had set, C<:encoding> included, so C<input> is read as
the binary it is and C<output> receives plaintext bytes -- decode them
yourself if the message was text.

Returns C<1> on success. Dies if a required argument is missing, if
C<identities> is not a non-empty ArrayRef -- L</decrypt> quotes the two
messages, one for the shape and one for the empty list -- if the header is
invalid, if no identity matches any stanza, if the MAC verification fails,
if payload authentication fails, or if C<binmode> fails on either handle.
Unlike L</decrypt_file>, this method never opens or closes a file itself --
C<input> and C<output> are handles the caller already has open -- so it cannot
die with a "file not found" or "permission denied" error; that is the
caller's concern before the handle is passed in.

Decryption streams: plaintext is written to C<output> one 64 KiB chunk at a
time as each chunk authenticates, so memory use does not grow with the amount
of data decrypted. B<This also means a failure does not undo what was already
written.> If the payload is truncated or corrupt, every chunk that
authenticated before the error is already in C<output> when this method dies;
each of those chunks is individually authentic, but the message as a whole is
not, which is exactly what the error reports. A caller must treat whatever
reached C<output> as unauthenticated and discard it, rather than as a decrypted
message merely because its individual bytes checked out. See
L<Crypt::Age::Primitives/decrypt_payload_fh> for the same guarantee stated at
the primitive layer.

=head1 KEY FORMAT

=head2 Public Keys

Public keys are Bech32-encoded X25519 public keys with the human-readable
part C<age>:

    age19ljhmg68e43yx9fgm2k9lwefquc0la5y4lzvlshdjzv47kxt8d6qr9vf4p

=head2 Secret Keys

Secret keys are uppercase Bech32-encoded X25519 secret keys with the
human-readable part C<AGE-SECRET-KEY->:

    AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ8H00W3

=head1 INTEROPERABILITY

This module is designed to be compatible with:

=over 4

=item * L<https://github.com/FiloSottile/age> - Reference Go implementation

=item * L<https://github.com/str4d/rage> - Rust implementation

=back

Files encrypted with Crypt::Age can be decrypted with these tools and vice versa.

=head1 LIMITATIONS

Only the C<X25519> recipient type is implemented, and it is complete in both
directions: keypair generation, header creation and parsing, wrapping and
unwrapping, and the header MAC. Not implemented:

=over 4

=item * scrypt (passphrase) recipients

=item * SSH recipients

=item * the post-quantum and tagged recipient types (C<mlkem768x25519> and
similar)

=item * ASCII armor

=back

A stanza of one of these types is not rejected outright: the format requires
unrecognized stanza types to be ignored, and this implementation does that (see
L<Crypt::Age::Header/parse_from_fh>), so a file with both an C<X25519>
recipient and, say, a C<scrypt> one still decrypts normally for an identity
that matches the C<X25519> stanza. But a file whose recipients are all of
these unsupported types dies: L</decrypt> and the other decrypt methods raise
C<"No matching identity found">, since L<Crypt::Age::Header/unwrap_file_key>
only tries stanzas it recognizes as C<X25519>. An armored file fails even
earlier, because its first line is not the literal C<age-encryption.org/v1>
version line that L<Crypt::Age::Header/parse_from_fh> requires. On the encrypt
side, passing a recipient string that is not a Bech32 C<age1...> public key
dies with C<"Unsupported recipient format at index N: expected an age1
recipient">, C<N> being that recipient's position in the C<recipients> array.
A suffix names what arrived instead wherever that can be said without quoting
it: a string that looks like a secret key adds C<", got an AGE-SECRET-KEY-1
identity">, and an C<undef> entry adds C<", got undef">. The rejected string
itself is never quoted back: it may be a secret key passed where a recipient
belongs, and the message would carry it into the caller's logs. See
L<Crypt::Age::Header/create>.

=head1 SECURITY

age uses modern cryptographic primitives:

=over 4

=item * X25519 for key agreement (Curve25519 Diffie-Hellman)

=item * ChaCha20-Poly1305 for authenticated encryption

=item * HKDF-SHA256 for key derivation

=back

The file key is randomly generated for each encryption operation. The payload
is encrypted in 64 KiB chunks with unique nonces derived from a counter and
final-chunk flag.

=head1 SEE ALSO

=over 4

=item * L<https://age-encryption.org> - age encryption homepage

=item * L<https://github.com/C2SP/C2SP/blob/main/age.md> - age format specification

=item * L<CryptX> - Cryptographic toolkit providing all primitives

=item * L<Crypt::Age::Header> - Header parsing, generation and the header MAC

=item * L<Crypt::Age::Stanza> - Base recipient stanza class

=item * L<Crypt::Age::Stanza::X25519> - X25519 recipient stanza

=item * L<Crypt::Age::Keys> - Key generation and encoding

=item * L<Crypt::Age::Primitives> - Low-level cryptographic operations

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-crypt-age/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
