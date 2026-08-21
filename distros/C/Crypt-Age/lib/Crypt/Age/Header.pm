package Crypt::Age::Header;
# ABSTRACT: age file header parsing and generation
our $VERSION = '0.002';
use Moo;
use Carp qw(croak);
use Crypt::Misc qw(slow_eq);
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::Age::Stanza::X25519;
use namespace::clean;


use constant VERSION_LINE => "age-encryption.org/v1";

has stanzas => (
    is      => 'ro',
    default => sub { [] },
);


has mac => (
    is => 'rw',
);


has _bytes => (
    is => 'lazy',
);

# The header bytes the MAC is computed over: everything up to and including the
# '---' of the footer line, without the space after it and without a trailing
# newline. Internal, hence the leading underscore and the matching constructor
# key used by parse_from_fh.
#
# On the read path parse_from_fh passes the literal bytes it read, so the MAC is
# verified against what the file actually contained. On the write path there is
# nothing to capture and the builder below re-serializes the stanzas instead.

sub create {
    my ($class, $file_key, $recipients) = @_;

    my @stanzas;
    for my $recipient (@$recipients) {
        if ($recipient =~ /^age1/) {
            push @stanzas, Crypt::Age::Stanza::X25519->wrap($file_key, $recipient);
        } else {
            croak "Unsupported recipient format: $recipient";
        }
    }

    my $header = $class->new(stanzas => \@stanzas);

    # Compute and set MAC
    my $header_bytes = $header->_bytes;
    my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $header_bytes);
    $header->mac($mac);

    return $header;
}


sub to_string {
    my ($self) = @_;

    my @lines = (VERSION_LINE);

    for my $stanza (@{$self->stanzas}) {
        push @lines, $stanza->to_string;
    }

    # MAC line
    my $mac_b64 = Crypt::Age::Stanza::encode_base64_no_padding($self->mac);
    push @lines, "--- $mac_b64";

    return join("\n", @lines) . "\n";
}


sub _build__bytes {
    my ($self) = @_;

    my @lines = (VERSION_LINE);

    for my $stanza (@{$self->stanzas}) {
        push @lines, $stanza->to_string;
    }

    # For MAC, we include everything up to but not including the MAC itself
    # The footer line is "---" (without the MAC)
    push @lines, "---";

    return join("\n", @lines);
}

sub parse_from_fh {
    my ($class, $fh) = @_;

    # make sure to read the whole thing in the correct way
    binmode($fh, ':raw') or croak "binmode: $!";
    local $/ = "\x{0a}";

    # $header will eventually contain the whole header, for MAC validation.
    # We start from the first line.
    my $bytes = <$fh>;

    # Check version
    chomp(my $version_line = $bytes); # remove \x{0a}
    croak "Invalid age version: $version_line" unless $version_line eq VERSION_LINE;

    # read the rest of the header
    my (@stanzas, $mac);
    my $n = 0;
    while (<$fh>) {
        if (my ($mac64) = m{\A ---\x{20} (\S{43}) \x{0a} \z}mxs) {
            $bytes .= '---';
            $mac = Crypt::Age::Stanza::decode_base64_no_padding($mac64);
            last;
        }
        ++$n;
        # c2sp.org/age, "ABNF definition of file header":
        #
        #     arg-line = "-> " argument *(SP argument) LF
        #     argument = 1*VCHAR
        #
        # VCHAR is RFC 5234's core rule %x21-7E, the printable ASCII
        # characters, so every argument is one or more of those and an empty
        # argument (two spaces in a row, or a trailing space) is not an
        # argument at all. The ABNF has no separate rule for the stanza type:
        # the type is simply the first argument and carries exactly the same
        # character set.
        #
        # This is why the check lives here rather than in a stanza class. The
        # character set is a property of the header's grammar, not of any one
        # recipient type, so a byte outside it makes the WHOLE header invalid
        # -- including in a stanza whose type we do not recognize and would
        # otherwise be required to ignore. Hence: validate before the type
        # dispatch below. (\S used to stand in for VCHAR here and let every
        # non-whitespace byte through, which is what the test kit's
        # stanza_invalid_character vector caught.)
        my ($ta) = m{\A ->\x{20} ([\x21-\x7e]+ (?:\x{20}[\x21-\x7e]+)*) \x{0a} \z}mxs
            or croak "Invalid age stanza #$n start line: expected '-> ' followed"
                . " by space-separated arguments of printable ASCII (0x21-0x7e)";

        $bytes .= $_;

        # Read stanza's body lines
        my $body_b64 = '';
        my $body_completed = 0;
        while (<$fh>) {
            $bytes .= $_;
            chomp;
            my $len = length($_);
            croak "Invalid age stanza #$n body" if $len > 64;
            $body_b64 .= $_;
            if ($len < 64) {
                $body_completed = 1;
                last;
            }
        }
        # "The body MUST end with a line shorter than 64 characters, which
        #  MAY be empty."
        croak "Invalid age stanza #$n body" unless $body_completed;

        my ($type, @args) = split m{\x{20}}mxs, $ta;
        my $body = Crypt::Age::Stanza::decode_base64_no_padding($body_b64);

        my $stanza_class = 'Crypt::Age::Stanza';
        if ($type eq 'X25519') {
            $stanza_class = 'Crypt::Age::Stanza::X25519';
        }

        push @stanzas, $stanza_class->new(
            type => $type,
            args => \@args,
            body => $body,
        );
    }
    croak "Invalid age file, no valid header MAC line" unless length($mac // '');

    return $class->new(
        stanzas => \@stanzas,
        _bytes  => $bytes,
        mac     => $mac,
    );
}


sub parse {
    my ($class, $data_ref, $offset_ref) = @_;
    open my $fh, '<:raw', $data_ref or croak "Invalid age input: cannot read";
    seek($fh, $$offset_ref // 0, 0);
    my $retval = $class->parse_from_fh($fh);
    $$offset_ref = tell($fh);
    return $retval;
}


sub verify_mac {
    my ($self, $file_key) = @_;

    my $header_bytes = $self->_bytes;
    my $expected_mac = Crypt::Age::Primitives->compute_header_mac($file_key, $header_bytes);

    # slow_eq is CryptX's XS wrapper around libtomcrypt's mem_neq: for two
    # equal-length strings it reads both in full instead of returning at the
    # first differing byte. It does not hide the length -- a length mismatch is
    # reported as unequal, which is fine here since the MAC length is fixed by
    # the format and not secret. undef compares as unequal rather than dying.
    return slow_eq($self->mac, $expected_mac) ? 1 : 0;
}


sub unwrap_file_key {
    my ($self, $identities) = @_;

    for my $identity (@$identities) {
        for my $stanza (@{$self->stanzas}) {
            if ($stanza->isa('Crypt::Age::Stanza::X25519') && $identity =~ /^AGE-SECRET-KEY-1/i) {
                my $file_key = $stanza->unwrap($identity);
                if (defined $file_key && $self->verify_mac($file_key)) {
                    return $file_key;
                }
            }
        }
    }

    croak "No matching identity found";
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Age::Header - age file header parsing and generation

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Crypt::Age::Header;

    # Create header for encryption
    my $header = Crypt::Age::Header->create($file_key, \@recipient_public_keys);
    my $header_text = $header->to_string;

    # Parse header during decryption
    my $offset = 0;
    my $header = Crypt::Age::Header->parse(\$ciphertext, \$offset);

    # Unwrap file key
    my $file_key = $header->unwrap_file_key(\@identity_secret_keys);

=head1 DESCRIPTION

This module handles parsing and generation of age file headers.

An age file header is a text section at the beginning of an age file that contains:

=over 4

=item * Version line (C<age-encryption.org/v1>)

=item * One or more recipient stanzas (each wrapping the file key)

=item * MAC footer (authenticates the header)

=back

The header format is:

    age-encryption.org/v1
    -> X25519 <base64-ephemeral-public-key>
    <base64-wrapped-file-key>
    --- <base64-mac>

This is an internal module used by L<Crypt::Age>.

=head2 stanzas

ArrayRef of L<Crypt::Age::Stanza> objects representing recipient stanzas.

Each stanza wraps the file key for one recipient.

=head2 mac

The header MAC as raw bytes (32 bytes).

Used to authenticate the header and verify that the correct file key was unwrapped.

=head2 create

    my $header = Crypt::Age::Header->create($file_key, \@recipients);

Creates a new header for encrypting to multiple recipients.

Parameters:

=over 4

=item * C<$file_key> - The 16-byte file key to wrap

=item * C<\@recipients> - ArrayRef of Bech32-encoded public keys (C<age1...>)

=back

Returns a L<Crypt::Age::Header> object with stanzas for each recipient and a
computed MAC.

=head2 to_string

    my $header_text = $header->to_string;

Serializes the header to text format.

Returns a string containing the version line, all stanzas, and the MAC footer,
suitable for writing to the beginning of an age file.

=head2 parse_from_fh

    my $header = Crypt::Age::Header->parse_from_fh($fh);

Parses an age header directly from a filehandle.

Parameters:

=over 4

=item * C<$fh> - An open, readable filehandle positioned at the first byte of
the header

=back

Puts the handle into C<:raw> mode and reads it line by line (with C<"\n"> as
the input record separator) for the duration of the call, so the caller does
not need to prepare the handle's discipline beforehand. It reads the version
line, every recipient stanza, and the C<---> MAC footer line, stopping as soon
as that footer line has been consumed. On return the handle is therefore
positioned at the first byte of the payload -- this is what lets L</parse>
call C<tell> on it afterwards to report the new offset.

While reading, it accumulates the literal header bytes it consumed -- the
version line, every stanza line exactly as read, and the C<---> of the footer,
with no trailing space, MAC value, or newline -- and stores them on the
returned object. L</verify_mac> authenticates against these captured bytes,
not against a re-serialization of the parsed stanzas, so a header this method
accepted is exactly the header the MAC is checked against. (Header
construction on the write path, L</create>, has no bytes to capture and
re-serializes the stanzas instead.)

Returns a L<Crypt::Age::Header> object holding the parsed stanzas, the raw MAC
bytes, and the captured header bytes. It does not verify the MAC itself -- that
is L</verify_mac>'s job, and it only runs after a file key has been unwrapped
from one of the stanzas.

Dies if:

=over 4

=item * the first line is not the literal C<age-encryption.org/v1> version
line

=item * a stanza body line is longer than 64 characters

=item * a stanza body never reaches a line shorter than 64 characters before
the handle runs out -- the required short (possibly empty) final line is
missing

=item * the handle runs out, or a line fails to match either a stanza start
line (C<-E<gt> type arg1 arg2 ...>) or the C<---> MAC footer (three dashes, a
space, and a 43-character base64 MAC), before a valid MAC line has been found

=item * a stanza start line carries an argument that is empty (two spaces in
a row, or a trailing space) or that contains a byte outside printable ASCII,
C<0x21>-C<0x7e> -- the format's C<argument = 1*VCHAR>, where C<VCHAR> is RFC
5234's core rule. The first argument, the stanza type, is subject to the same
set: the grammar defines no separate rule for it. This check applies to every
stanza line in the header regardless of type, and rejecting is deliberate --
a byte outside the set invalidates the whole header rather than merely making
that one stanza ignorable

=item * a stanza body, a stanza argument, or the MAC token fails the strict
decoding in L<Crypt::Age::Stanza/decode_base64_no_padding> -- C<=> padding, a
character outside the base64 alphabet, an impossible length, or a
non-canonical encoding

=item * an C<X25519> stanza fails the checks in
L<Crypt::Age::Stanza::X25519/BUILD>: other than exactly one argument after the
type, an argument that does not decode to a 32-byte value, or a body that is
not exactly 32 bytes

=back

A stanza of an unrecognized type is kept as a plain L<Crypt::Age::Stanza> and
is not validated beyond the structure every stanza shares -- the format
requires unknown stanzas to be ignored, not rejected, since this is how
recipient types are expected to be added in the future (grease). "The
structure every stanza shares" does include the argument character set above:
an unknown-type stanza whose arguments are all printable ASCII is ignored,
one carrying a byte outside that set is a header failure, because the byte
breaks the header's grammar rather than that one stanza's semantics.

This is the implementation L</parse> wraps for its C<\$data>/C<\$offset>
interface; see L</parse> for that entry point.

=head2 parse

    my $header = Crypt::Age::Header->parse(\$data, \$offset);

Parses an age header from encrypted data. This is a C<\$data>/C<\$offset>
wrapper: it opens a filehandle on C<\$data> and delegates the actual parsing
to L</parse_from_fh>.

Parameters:

=over 4

=item * C<\$data> - ScalarRef to the complete age file data

=item * C<\$offset> - ScalarRef to offset, updated to point past the header

=back

Returns a L<Crypt::Age::Header> object. The C<$offset> is updated to point to
the start of the payload.

Dies if the header format is invalid. That includes a malformed C<X25519>
stanza: one that does not carry exactly one argument after the type, whose
argument is not the canonical unpadded base64 encoding of a 32-byte value, or
whose body is not exactly 32 bytes. Those are header failures and are raised
here, before any identity is looked at, rather than being deferred to
L</unwrap_file_key> and mistaken there for a stanza that simply does not match
the identity. See L<Crypt::Age::Stanza::X25519/BUILD>.

Stanzas of unrecognized types are kept as plain L<Crypt::Age::Stanza> objects
and are not validated beyond the structure every stanza shares; the format
requires them to be ignored, not rejected.

=head2 verify_mac

    my $ok = $header->verify_mac($file_key);

Verifies that the header MAC is correct for the given file key.

Returns C<1> if the MAC is valid, C<0> otherwise. Used to confirm that the
correct file key was unwrapped from a stanza.

The comparison goes through C<slow_eq> from L<Crypt::Misc>, so a wrong MAC is
not rejected at the first differing byte. A MAC of the wrong length -- or no
MAC at all -- returns C<0>; it is never fatal.

=head2 unwrap_file_key

    my $file_key = $header->unwrap_file_key(\@identities);

Attempts to unwrap the file key using one or more identities.

Parameters:

=over 4

=item * C<\@identities> - ArrayRef of Bech32-encoded secret keys (C<AGE-SECRET-KEY-1...>)

=back

Tries each identity against each stanza until one successfully unwraps the file
key and verifies the MAC. Returns the 16-byte file key. Stanzas of other types
are skipped, so a file that mixes recipient types still decrypts.

Dies if no matching identity is found or if MAC verification fails. It does not
die for a structurally invalid C<X25519> stanza -- L</parse> has already
rejected the header by then -- but it does propagate the abort that a
low-order-point ephemeral share triggers, since that is a header failure too and
not a wrong identity.

=head1 SEE ALSO

=over 4

=item * L<Crypt::Age> - Main age encryption module

=item * L<Crypt::Age::Stanza> - Base stanza class

=item * L<Crypt::Age::Stanza::X25519> - X25519 recipient stanza

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
