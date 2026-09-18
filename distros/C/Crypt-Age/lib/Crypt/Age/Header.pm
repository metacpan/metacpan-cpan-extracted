package Crypt::Age::Header;
# ABSTRACT: age file header parsing and generation
our $VERSION = '0.004';
use Moo;
use Carp qw(croak);
use Crypt::Misc qw(slow_eq);
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::Age::Stanza::X25519;
use namespace::clean;


use constant VERSION_LINE => "age-encryption.org/v1";

# The one number in this module that c2sp.org/age does NOT dictate. Its ABNF is
# "header = v1-line 1*stanza end" -- one or more, with no upper bound -- and
# neither reference implementation imposes one: age 1.2.1 reads a 50000-stanza
# header (8.9 s), rage 0.12.1 a 4000-stanza one (5.81 s). See parse_from_fh for
# why we deviate and how a caller opts out.
use constant DEFAULT_MAX_STANZAS => 128;

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

    # The shape check the loop below assumed. $#{$recipients} dereferences
    # whatever arrives, so every wrong shape used to be reported by perl from
    # inside this module: a plain string as "Can't use string (\"...\") as an
    # ARRAY ref while \"strict refs\" in use", undef as "Can't use an undefined
    # value as an ARRAY reference", any other ref as "Not an ARRAY reference".
    #
    # The first of those quotes the caller's string, truncated at perl's 32
    # characters. Here that string is normally a recipient and so public, but
    # the mistake that puts a bare string in this parameter is the same one
    # that swaps recipient and identity -- both are plain strings, and the
    # croak below in the loop exists because that swap happens -- so the value
    # perl would quote is not reliably a public one. Nothing is interpolated,
    # for the reason written out at that croak and again in unwrap_file_key.
    #
    # The clause after the colon carries the requirement and its reason rather
    # than a description of what arrived, because one message answers all three
    # shapes above.
    croak 'recipients must be an ArrayRef: this method wraps the file key '
        .'once per entry, pass [$recipient] rather than $recipient'
        if ref $recipients ne 'ARRAY';

    # The spec's header grammar is "header = v1-line 1*stanza end": one or
    # more stanzas, never zero. An empty list satisfied the check above and
    # returned a header of a version line and a MAC over it, wrapping the file
    # key for nobody -- so the file it starts can never be decrypted, by the
    # caller least of all, since the file key is generated per file and kept
    # nowhere else. Measured on a file built from such a header: rage 0.12.1
    # refuses it as "Unknown age format" because the grammar is not satisfied,
    # age 1.2.1 parses it and fails with "no identity matched any of the
    # recipients". Both are right, and both say so once the plaintext is gone.
    #
    # Same skeleton as the check above, carrying this method's own reason.
    croak 'recipients must not be empty: this method wraps the file key once '
        .'per entry, so a header with no stanzas can never be unwrapped, '
        .'pass at least one recipient'
        unless @$recipients;

    my @stanzas;
    for my $i (0 .. $#{$recipients}) {
        my $recipient = $recipients->[$i];
        # The prefix test is case-insensitive because BIP-173 makes the
        # all-uppercase form the same encoding of the same string, and
        # Keys::decode_public_key already accepts it. A mixed-case recipient
        # still dies: it reaches decode_public_key and is rejected there by
        # bech32_decode's mixed-case guard.
        #
        # Definedness is tested first so that an undef entry never reaches this
        # pattern match, nor the one in the hint below. Both would emit a "Use
        # of uninitialized value" warning -- noise from library code, arriving
        # ahead of the croak that actually explains the problem. The entry is
        # rejected either way; undef is not an age1 recipient.
        if (defined $recipient && $recipient =~ /^age1/i) {
            push @stanzas, Crypt::Age::Stanza::X25519->wrap($file_key, $recipient);
        } else {
            # Never interpolate $recipient. The likeliest way to reach this
            # croak is a caller swapping recipient and identity -- both are
            # plain strings -- and the exception travels into whatever log
            # catches it, so echoing the string puts a whole secret key there.
            # The message is therefore built from literals plus the array
            # index, which locates the bad entry in the caller's own array and
            # copies no byte of it. The identity hint is a classification
            # against a public format prefix, not a quotation of the value: it
            # carries one bit about a constant that every age tutorial prints,
            # and structurally cannot expose key material. age(1) and rage(1)
            # do echo the string, but there it was already a command-line
            # argument; a library error message is not.
            #
            # undef gets no message of its own: ", got undef" fills the same
            # "what arrived instead" slot the identity hint already occupies,
            # so the skeleton and the prefix stay one shape, and one croak
            # keeps the variants from drifting apart. It is a classification
            # too -- there is nothing to interpolate in the first place.
            my $hint = !defined $recipient ? ', got undef'
                : $recipient =~ /^AGE-SECRET-KEY-1/i
                ? ', got an AGE-SECRET-KEY-1 identity' : '';
            croak 'Unsupported recipient format at index '.$i
                .': expected an age1 recipient'.$hint;
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
    my ($class, $fh, @opt) = @_;

    # Checked before the hash assignment below, which would otherwise warn
    # "Odd number of elements in hash assignment" out of this file for a
    # mistake made one frame up -- the same reasoning as the shape checks in
    # parse. The mis-call worth catching is parse_from_fh($fh, 300): the limit
    # passed positionally is silently not a limit, so the default one below
    # still refuses the caller's 300-recipient file and tells them to pass
    # max_stanzas, which is exactly what they thought they had done. Nothing is
    # interpolated: a caller who got the arguments wrong here may have put an
    # identity in this position.
    croak 'parse_from_fh takes a filehandle followed by named options: '
        .'pass max_stanzas => $n rather than a bare value'
        if @opt % 2;
    my %opt = @opt;

    # Our own denial-of-service limit, and the only constant here that is not
    # the format's -- see DEFAULT_MAX_STANZAS above. It exists because the cost
    # of a header is paid before any of it can be authenticated: the header MAC
    # key is derived from the file key, which does not exist until a stanza has
    # been unwrapped, so unwrap_file_key has to try every identity against every
    # stanza -- an X25519 scalar multiplication, an HKDF and a ChaCha20-Poly1305
    # open each -- on a header nobody has vouched for. Measured on 0.003, ~3.9
    # ms per stanza per identity: 98 attacker-controlled bytes buy a scalar
    # multiplication, 382 KB buy 15.7 s (CVE-2026-85783).
    #
    # 128 is a maintainer decision, not a measurement of the format. What the
    # measurements say is where the room is: the upstream test kit tops out at
    # three stanzas and real files carry a handful, but `age -R` writes a
    # 300-recipient file without complaint and a real 301-recipient file from
    # age 1.2.1 decrypts here correctly in 1.17 s. So this cap deliberately
    # rejects files a reference implementation produces, which is why it MUST
    # stay overridable and why the croak below names max_stanzas: a caller who
    # legitimately has such a file needs to be told how to read it.
    #
    # A missing max_stanzas means the default. An explicit undef or 0 is an
    # error rather than "no limit": 0 read literally means "allow zero stanzas",
    # which the grammar forbids anyway, so taking it as "allow unbounded" would
    # invert the most natural reading of the value -- and a security limit that
    # a falsy value silently switches off is one that disappears exactly when a
    # caller computes it and the computation goes wrong. A caller who wants
    # age's unbounded behaviour asks for a number large enough to say so.
    my $max_stanzas = exists $opt{max_stanzas} ? $opt{max_stanzas}
                                               : DEFAULT_MAX_STANZAS;
    croak 'max_stanzas must be a positive integer: it caps how many recipient '
        .'stanzas this header may carry, and 0 or undef would be a header no '
        .'identity could ever unwrap, pass a number large enough for the files '
        .'you read'
        unless defined $max_stanzas
            && $max_stanzas =~ m{\A[0-9]+\z}
            && $max_stanzas > 0;

    # make sure to read the whole thing in the correct way
    binmode($fh, ':raw') or croak "binmode: $!";
    local $/ = "\x{0a}";

    # $header will eventually contain the whole header, for MAC validation.
    # We start from the first line.
    my $bytes = <$fh>;

    # readline gives undef at end of input, and arriving here with nothing to
    # read is a legitimate "this is not an age file": an empty $data, or an
    # offset already at its end. That is exactly what the version croak below
    # reports -- but chomp and eq on undef warned out of this file first, with
    # line numbers from here for a mistake made one frame up. An absent version
    # line is not the expected literal either, so carry it into the same check
    # the empty first line takes rather than warning on the way to it.
    $bytes = '' unless defined $bytes;

    # Check version
    chomp(my $version_line = $bytes); # remove \x{0a}
    # Never interpolate $version_line: reaching this croak means the input is
    # not an age file, so the line is whatever the caller handed over -- a line
    # of plaintext, or the entire input when it contains no newline at all.
    # The check is against a single literal, so naming the expected value says
    # everything the caller needs without quoting theirs.
    croak 'Invalid age version: expected the literal '.VERSION_LINE
        .' version line' unless $version_line eq VERSION_LINE;

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
        # Here rather than on @stanzas after the loop, and before this stanza's
        # arg line is even matched: the point of the limit is that the work is
        # never done. Refusing after the fact would still have read the whole
        # 382 KB header into $bytes and built every stanza object; refusing here
        # stops at the first line of stanza max+1, so neither the body nor any
        # of the scalar multiplications that follow it are ever paid for.
        #
        # Only $max_stanzas is interpolated, and it is the caller's own value.
        # $n is not: it is always $max_stanzas + 1 here, so it says nothing the
        # message does not, and the count comes from the header, which is
        # attacker-controlled input that this module quotes nowhere.
        croak 'age header carries more than '.$max_stanzas.' recipient '
            .'stanzas: every stanza costs an X25519 scalar multiplication per '
            .'identity before any of the header can be authenticated, so an '
            .'unbounded header is a denial of service, this limit comes from '
            .'this implementation and not from the age format, raise it with '
            .'max_stanzas if the file is a legitimate one'
            if $n > $max_stanzas;
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

    # c2sp.org/age, "ABNF definition of file header":
    #
    #     header = v1-line 1*stanza end
    #
    # One or more stanzas, never zero, and the prose above that grammar says
    # it again in words: "followed by one or more recipient stanzas". A
    # version line followed straight by the MAC footer passed every check
    # above and parsed into a header with an empty stanza list -- one whose
    # MAC even verifies, because it is a well-formed MAC over a header the
    # grammar forbids. Nothing here refused it, so such a file travelled on to
    # unwrap_file_key and died there with "No matching identity found", naming
    # the caller's keys as the cause of a file that is addressed to nobody at
    # all.
    #
    # This is an interop difference, not only a tidiness one, which is why it
    # is refused rather than tolerated. Measured on such a file: rage 0.12.1
    # rejects it at parse time as "Unknown age format", age 1.2.1 parses it
    # and reports "no identity matched any of the recipients". This
    # implementation was the most permissive of the three; it now refuses
    # where rage does, at the point the grammar is actually violated.
    #
    # After the MAC check on purpose. A truncated header -- a version line and
    # nothing after it -- carries no stanzas either, but its cause is that the
    # handle ran out, which the croak above already names; only a header that
    # is complete and stanza-less reaches this line.
    #
    # #36 put the same clause on the write side, in create. Nothing is
    # interpolated here: reaching this croak says nothing about the caller's
    # arguments, and the header it describes is the file's, not theirs.
    croak 'age header must carry at least one recipient stanza: the file key '
        .'is wrapped once per stanza, so a header with none can never be '
        .'unwrapped by anyone, decrypt a file encrypted to at least one '
        .'recipient'
        unless @stanzas;

    return $class->new(
        stanzas => \@stanzas,
        _bytes  => $bytes,
        mac     => $mac,
    );
}


sub parse {
    my ($class, $data_ref, $offset_ref, @opt) = @_;

    # The type test perl's open does not do for us. Everything below assumes a
    # ScalarRef -- the scan dereferences it, and the open maps it into an
    # in-memory handle -- but open silently means something else for every
    # other shape, and the wrong meanings are worse than an error: a plain
    # string is a *filename*, so a caller who drops the backslash reads the
    # file that string names, measured here as parse returning a header built
    # from that file and advancing the caller's $offset past it. A blessed
    # SCALAR ref stringifies into a filename the same way, a REF reads back the
    # address of the inner ref, and undef warned out of this module about a
    # mistake made one frame up. So: ref eq 'SCALAR', the only shape that maps
    # to the bytes the caller meant -- open takes a REF too, it just reads
    # something else -- checked before anything touches the argument.
    #
    # Never interpolate $data_ref. This is the one path where perl's own
    # message would do it for us -- the string it would quote is either the
    # ciphertext the caller meant to pass or a filesystem path.
    croak 'data must be a ScalarRef: this method opens it, and a plain string '
        .'is a filename, pass \$data rather than $data'
        if ref $data_ref ne 'SCALAR';

    # The same test for the second parameter, and here for the opposite
    # reason: nothing is read through this ref -- the new offset is written
    # back out through it, which is how the caller learns where the payload
    # starts, and only a ref carries a value back out of a call. Both shape
    # checks sit before the scan below on purpose. They decide whether this
    # call can succeed at all, while the scan reads the caller's data, so a
    # complaint about that data is worth producing only once the call itself
    # is well formed -- and a caller who passed the two arguments the other
    # way round is exactly such a call, wrong in both of them.
    #
    # Never interpolate $offset_ref either, for the same reason as above with
    # the arguments swapped: perl's own "Can't use string (...) as a SCALAR
    # ref" quoted the ciphertext that lands here, and blamed a line in this
    # file for a mistake made one frame up.
    croak 'offset must be a ScalarRef: this method writes the new offset back '
        .'through it, pass \$offset rather than $offset'
        if ref $offset_ref ne 'SCALAR';

    # And now the content, before anything dereferences it for real. A ref to
    # an undefined scalar passes both shape checks above -- it genuinely is a
    # ScalarRef -- and then reached the scan below, the open under it and the
    # readline in parse_from_fh, warning ten times about uninitialized values
    # with line numbers from this file for a mistake made one frame up.
    #
    # This gets a croak of its own rather than being normalized to the empty
    # string and left to the version-line croak in parse_from_fh, because the
    # two are different mistakes with different fixes: "there is nothing behind
    # the ref you handed me" is a caller error, while "these bytes are not an
    # age file" is a statement about data that really arrived. Folding the
    # first into the second would name a cause the caller does not have. Empty
    # bytes stay the second kind and still get the version-line croak, which
    # no longer warns on its way there either -- see parse_from_fh.
    #
    # Nothing interpolated here either, for the reason given above: there is no
    # value to quote in this case, and the message must read the same when the
    # check moves or the caller's scalar turns out to hold ciphertext.
    croak 'data must refer to a defined scalar: this method reads the age '
        .'file out of it, assign the bytes before passing \$data'
        unless defined $$data_ref;

    # Perl's own test for the in-memory open below, hoisted so the failure
    # names its cause instead of arriving as "cannot read". The reasoning is
    # written out over the same check in Crypt::Age::encrypt; the delta here is
    # the mechanism. That one may downgrade because it holds a copy off @_, and
    # "our own copy" is the whole safety argument -- it does not carry when the
    # parameter is the caller's scalar behind a ref, so this reads instead of
    # converting. The scan is free on the unflagged byte string this is
    # normally given (200 passes over 16 MiB: 0.00s CPU, against 11.4s on a
    # flagged one), and nothing internal repeats it -- lib/ reaches the parser
    # through parse_from_fh, so parse has no caller here. It buys less than it
    # looks: on success perl's open downgrades the referenced scalar in place
    # anyway, so what is ours is only that a rejected $data is left as it was.
    # Dereferencing needs no guard of its own: the check above settled the type.
    croak 'data must be a byte string: it holds a code point above 0xFF, '
        .'read it with :raw rather than decoding it'
        if $$data_ref =~ /[^\x00-\xff]/;

    open my $fh, '<:raw', $data_ref or croak "Invalid age input: cannot read";
    seek($fh, $$offset_ref // 0, 0);
    # Named options travel on unread and unvalidated: max_stanzas is
    # parse_from_fh's, and duplicating its check here would be a second place
    # to keep the message and the default in step. An odd @opt is caught there
    # too, before it can warn.
    my $retval = $class->parse_from_fh($fh, @opt);
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

    # The same shape check as in create, and the one place in this distribution
    # where omitting it leaked a secret. @$identities dereferences whatever
    # arrives, and for a bare string perl reports "Can't use string (\"...\")
    # as an ARRAY ref while \"strict refs\" in use" with the first 32
    # characters of that string quoted in it. The string in this parameter is
    # an identity, so those 32 characters are secret key material, written into
    # an exception by this module -- and an exception travels into logs, bug
    # reports and terminal scrollback that the caller cannot redact after the
    # fact. A single identity passed without the brackets is the likeliest way
    # to get here at all, since one identity does not look like a list.
    #
    # undef and other refs reach the same dereference and are answered by the
    # same message; as in create it carries the requirement and its reason, and
    # quotes nothing.
    croak 'identities must be an ArrayRef: this method tries each entry in '
        .'turn, pass [$identity] rather than $identity'
        if ref $identities ne 'ARRAY';

    for my $identity (@$identities) {
        # Skipped before the prefix test below, which would otherwise emit a
        # "Use of uninitialized value" warning once per X25519 stanza. Skipping
        # is exactly what already happens to any string that is not an
        # AGE-SECRET-KEY-1: unlike a recipient in create, an identity that does
        # not match is not an error, it is simply not the one. So this drops
        # the warnings and changes no outcome -- a list whose entries all fail
        # to unwrap still ends at the croak below.
        next unless defined $identity;

        # Hoisted out of the stanza loop below, where it used to sit in the
        # same condition as the isa test: it asks about the identity only, so
        # asking it once per identity rather than once per stanza changes no
        # outcome. An identity that is not an AGE-SECRET-KEY-1 was already
        # skipped against every stanza; it is now skipped once.
        next unless $identity =~ /^AGE-SECRET-KEY-1/i;

        # Built at the first X25519 stanza this identity is tried against, and
        # then reused for the rest of them. The Bech32 decode and the scalar
        # multiplication that recovers the identity's own public key depend on
        # the identity and not on the stanza -- on a header with many stanzas
        # that was the same work done again per stanza for no reason. Measured
        # over 500 stanzas and one identity: 3.95 ms per stanza before, 2.71 ms
        # after, so ~31% of the cost went (the CPANSec report for
        # CVE-2026-85783 estimates ~36%). The rest is the shared-secret scalar
        # multiplication, which is per stanza by construction.
        #
        # Lazily, not before the loop, because decode_secret_key dies on an
        # invalid identity: deriving eagerly would move that death earlier, to
        # a header whose stanzas are all of some other type, where today the
        # identity is never decoded at all and the call ends in "No matching
        # identity found". The // keeps the failure exactly where it was.
        my $identity_keys;
        for my $stanza (@{$self->stanzas}) {
            next unless $stanza->isa('Crypt::Age::Stanza::X25519');
            $identity_keys //= Crypt::Age::Stanza::X25519->identity_keys($identity);
            my $file_key = $stanza->unwrap($identity, $identity_keys);
            if (defined $file_key && $self->verify_mac($file_key)) {
                return $file_key;
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

version 0.004

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

C<\@recipients> must really be an ArrayRef; a single recipient still goes in a
list of one. Every other shape used to reach a raw dereference and be reported
by perl as C<"Can't use string (...) as an ARRAY ref while "strict refs" in
use">, C<"Can't use an undefined value as an ARRAY reference"> or C<"Not an
ARRAY reference">, each of them blaming a line in this module for a mistake
made one frame up. They are now refused, before the file key is wrapped, with
C<"recipients must be an ArrayRef: this method wraps the file key once per
entry, pass [$recipient] rather than $recipient">. As elsewhere in this module
the clause after the colon carries the requirement and its reason rather than a
description of what arrived, since one message answers all of those shapes.

It quotes no part of the argument either. The first of perl's messages above
quoted the caller's string, truncated at 32 characters; the string in this
parameter is normally a public key, but the mistake that puts a bare string
here is the same one that swaps recipient and identity, which is why the
per-entry croak below reports that swap. See L</unwrap_file_key>, where the
value is never public.

An B<empty> ArrayRef is refused as well, with C<"recipients must not be empty:
this method wraps the file key once per entry, so a header with no stanzas can
never be unwrapped, pass at least one recipient">. It used to be accepted: it
passed the shape check, wrapped the file key for nobody, and returned a header
consisting of a version line and a MAC over it. The age header grammar is
C<header = v1-line 1*stanza end> -- one or more stanzas -- so that was not a
valid header at all, and the file it started could never be decrypted by
anyone, the caller included, because the file key is generated per file and
kept nowhere else. C<rage> 0.12.1 refuses such a file as C<"Unknown age
format">; C<age> 1.2.1 parses it and reports C<"no identity matched any of the
recipients">. Both arrive after the plaintext is unrecoverable, which is why
this is refused here instead.

Returns a L<Crypt::Age::Header> object with stanzas for each recipient and a
computed MAC.

The C<age1> prefix is matched case-insensitively, so an all-uppercase
C<AGE1...> recipient is accepted as well -- BIP-173 defines it as the same
encoding of the same key, and L<Crypt::Age::Keys/decode_public_key> decodes it.
A recipient mixing the two cases is not: it dies with C<Invalid bech32: mixed
case> from L<Crypt::Age::Keys/bech32_decode>. Any other recipient string dies
with C<"Unsupported recipient format at index N: expected an age1 recipient">,
where C<N> is the recipient's position in C<\@recipients>. A string that looks
like an identity adds C<", got an AGE-SECRET-KEY-1 identity"> -- the swap of
recipient and identity is the likely mistake, and both are plain strings.

An C<undef> entry dies with that same message and C<", got undef"> in place of
the identity hint; it is reported before any string operation touches it, so it
no longer produces two C<"Use of uninitialized value"> warnings ahead of the
error that explains it.

The offending string itself is never part of the message. It may be a secret
key, and the exception ends up in the caller's logs; the index locates the
entry without quoting it.

The case of the recipient string does not reach the file. It is decoded to raw
bytes here, and the stanza carries the ephemeral public key, not the recipient.

=head2 to_string

    my $header_text = $header->to_string;

Serializes the header to text format.

Returns a string containing the version line, all stanzas, and the MAC footer,
suitable for writing to the beginning of an age file.

=head2 parse_from_fh

    my $header = Crypt::Age::Header->parse_from_fh($fh);
    my $header = Crypt::Age::Header->parse_from_fh($fh, max_stanzas => 512);

Parses an age header directly from a filehandle.

Parameters:

=over 4

=item * C<$fh> - An open, readable filehandle positioned at the first byte of
the header

=item * C<max_stanzas> - Optional. The largest number of recipient stanzas this
header may carry, C<128> by default. A header with more is refused while it is
being read; see L</THE STANZA LIMIT> below

=back

Any option must be given as a name/value pair. C<parse_from_fh($fh, 300)>, the
limit passed positionally, is refused with C<"parse_from_fh takes a filehandle
followed by named options: pass max_stanzas =E<gt> $n rather than a bare value">
rather than warning about an odd number of hash elements and then silently
applying the default limit anyway.

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
line -- including when there is no first line at all, because the handle is
already at end of input. That case reads as an absent version line and gets
the same message, without warning about the C<undef> that C<readline> returned

=item * a stanza body line is longer than 64 characters

=item * a stanza body never reaches a line shorter than 64 characters before
the handle runs out -- the required short (possibly empty) final line is
missing

=item * the handle runs out, or a line fails to match either a stanza start
line (C<-E<gt> type arg1 arg2 ...>) or the C<---> MAC footer (three dashes, a
space, and a 43-character base64 MAC), before a valid MAC line has been found

=item * the header is complete but carries no recipient stanza at all -- a
version line followed directly by the C<---> MAC footer. The format's grammar
is C<header = v1-line 1*stanza end>, one or more, so such a header is
structurally invalid however well-formed its MAC is

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

=item * the header carries more recipient stanzas than C<max_stanzas> allows,
C<128> unless the caller says otherwise. Unlike every other entry in this list
this one is not a violation of the format; see L</THE STANZA LIMIT>

=item * C<max_stanzas> is given as C<undef>, C<0>, a negative number or
anything that is not a positive integer

=back

The stanza-less header is refused with C<"age header must carry at least one
recipient stanza: the file key is wrapped once per stanza, so a header with
none can never be unwrapped by anyone, decrypt a file encrypted to at least
one recipient">. It used to be accepted: the header parsed, and its MAC even
verified, since it is a well-formed MAC over a header the grammar forbids. The
file then failed later in L</unwrap_file_key> with C<"No matching identity
found">, which names the caller's keys as the cause of a file that is
addressed to nobody at all. Implementations disagree on when such a file is
rejected -- C<rage> 0.12.1 refuses it at parse time as C<"Unknown age
format">, C<age> 1.2.1 parses it and reports C<"no identity matched any of the
recipients"> -- and this one now refuses where C<rage> does, at the point the
grammar is violated. L</create> refuses to build such a header on the write
side.

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
    my $header = Crypt::Age::Header->parse(\$data, \$offset, max_stanzas => 512);

Parses an age header from encrypted data. This is a C<\$data>/C<\$offset>
wrapper: it opens a filehandle on C<\$data> and delegates the actual parsing
to L</parse_from_fh>.

Parameters:

=over 4

=item * C<\$data> - ScalarRef to the complete age file data

=item * C<\$offset> - ScalarRef to offset, updated to point past the header

=item * C<max_stanzas> - Optional, as in L</parse_from_fh>, which is where it
is validated and applied. See L</THE STANZA LIMIT>

=back

C<\$data> must really be a ScalarRef. Anything else is rejected before the
data is looked at, with C<"data must be a ScalarRef: this method opens it, and
a plain string is a filename, pass \$data rather than $data">. That names the
reason the check exists rather than describing what arrived: this method opens
a filehandle on its first argument, and perl maps only an unblessed SCALAR ref
into memory -- a plain string is a B<filename>, so a caller who wrote
C<parse($data, \$offset)> without the backslash used to read the file that
string names, and got a header parsed out of it rather than a type error.
C<undef>, a blessed scalar ref, a ref to a ref and every other shape are
refused by the same check and get the same message. It quotes no part of the
argument, since here that argument is either ciphertext or a path.

C<\$offset> must be a ScalarRef too, for the opposite reason: it is an
B<out-parameter>. Nothing is read through it beyond the offset to start at --
the new offset is written back out through the same ref, which is how the
caller learns where the payload begins, and only a ref carries a value back
out of a call. Every other shape used to reach a raw dereference and be
reported by perl as C<"Can't use string (...) as a SCALAR ref while "strict
refs" in use">, C<"Can't use an undefined value as a SCALAR reference"> or
C<"Not a SCALAR reference">, each of them blaming a line in this module for a
mistake made one frame up. They are now refused with C<"offset must be a
ScalarRef: this method writes the new offset back through it, pass \$offset
rather than $offset">. As above, the clause after the colon carries the
requirement and its reason rather than a description of what arrived, since
one message answers all of those shapes; and it quotes no part of the
argument, which for a caller who passed the two arguments the other way round
is the ciphertext.

Both argument shapes are settled before anything looks at the data, so a call
that is malformed in its second argument is reported as that, and never first
as a complaint about the first argument's contents.

The scalar C<\$data> refers to must also be B<defined>. A ScalarRef to an
undefined scalar -- C<parse(\my $undef, \$offset)> -- satisfies both shape
checks above and used to reach the byte-string scan, the in-memory open under
it and the readline in L</parse_from_fh>, raising ten C<"Use of uninitialized
value"> warnings carrying line numbers from inside this module before it
croaked. It is now refused with C<"data must refer to a defined scalar: this
method reads the age file out of it, assign the bytes before passing \$data">.

That is deliberately B<not> the same error as an empty or otherwise
unparseable C<$data>, which keeps the plain C<"Invalid age version: expected
the literal age-encryption.org/v1 version line">. A ref to nothing is a
mistake in the call; bytes that are not an age file are a statement about data
that really arrived, and the two have different fixes. Neither path warns.

Returns a L<Crypt::Age::Header> object. The C<$offset> is updated to point to
the start of the payload.

Dies if the header format is invalid. That includes a malformed C<X25519>
stanza: one that does not carry exactly one argument after the type, whose
argument is not the canonical unpadded base64 encoding of a 32-byte value, or
whose body is not exactly 32 bytes. Those are header failures and are raised
here, before any identity is looked at, rather than being deferred to
L</unwrap_file_key> and mistaken there for a stanza that simply does not match
the identity. See L<Crypt::Age::Stanza::X25519/BUILD>.

A header carrying B<no> recipient stanza at all is a header failure for the
same reason and is raised in the same place. The format's grammar is C<header
= v1-line 1*stanza end> -- one or more -- so a version line followed directly
by the C<---> footer is not a header, and letting it through used to surface
one call later as C<"No matching identity found">, which is the wrong cause
for a file addressed to nobody. See L</parse_from_fh> for the message.

Stanzas of unrecognized types are kept as plain L<Crypt::Age::Stanza> objects
and are not validated beyond the structure every stanza shares; the format
requires them to be ignored, not rejected.

The scalar C<\$data> refers to must hold B<bytes>. One holding a code point
above C<0xFF> cannot be mapped into a filehandle at all and is rejected before
anything else happens, with C<"data must be a byte string: it holds a code
point above 0xFF, read it with :raw rather than decoding it">; see
L<Crypt::Age/decrypt> for what this check does and does not catch.

Unlike the same check in L<Crypt::Age/encrypt>, L<Crypt::Age/decrypt> and
L<Crypt::Age::Primitives/encrypt_payload>, which downgrade a copy of the
string they were passed, this one only B<reads> C<$data>: it is the caller's
own scalar, not ours. On the success path that buys nothing observable --
perl's in-memory C<open> downgrades the referenced scalar in place, so a
C<$data> stored upgraded whose code points all fit in a byte comes back
downgraded whether this check is there or not. What it does guarantee is that
a B<rejected> C<$data> is left exactly as the caller had it, and that the
conversion on the success path stays perl's rather than this method's.

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

C<\@identities> must really be an ArrayRef; a single identity still goes in a
list of one. That is the call which used to get this wrong, because one
identity does not look like a list -- and here the check is a confidentiality
one. A bare identity string reached a raw dereference and was reported by perl
as C<"Can't use string (...) as an ARRAY ref while "strict refs" in use">,
where the C<(...)> is the first 32 characters of the identity: secret key
material, placed in an exception by this module, on its way into whatever log,
bug report or terminal scrollback catches it, where the caller can no longer
redact it. C<undef> and other refs reached the same dereference and were
reported as C<"Can't use an undefined value as an ARRAY reference"> or C<"Not
an ARRAY reference">.

All of them are now refused, before any identity is looked at, with
C<"identities must be an ArrayRef: this method tries each entry in turn, pass
[$identity] rather than $identity">, which carries the requirement and its
reason and no byte of the argument.

Tries each identity against each stanza until one successfully unwraps the file
key and verifies the MAC. Returns the 16-byte file key. Stanzas of other types
are skipped, so a file that mixes recipient types still decrypts.

The work is therefore identities times stanzas, and none of it can be avoided
by checking the header MAC first: the MAC key is derived from the file key,
which is what this method is trying to obtain. Each identity's raw keys are
derived once, at the first C<X25519> stanza it is tried against, rather than
once per stanza; the stanza count itself is capped by L</parse_from_fh>, see
L</THE STANZA LIMIT>.

An C<undef> entry in C<\@identities> is skipped, silently and without warning,
exactly as any other string that is not an C<AGE-SECRET-KEY-1> identity is: an
identity that does not match is not an error here, only a list where none of
them matches is. Unlike a recipient in L</create>, it is therefore not fatal on
its own.

Dies if no matching identity is found or if MAC verification fails. It does not
die for a structurally invalid C<X25519> stanza -- L</parse> has already
rejected the header by then -- but it does propagate the abort that a
low-order-point ephemeral share triggers, since that is a header failure too and
not a wrong identity.

=head1 THE STANZA LIMIT

C<max_stanzas> is this distribution's own limit and not the age format's. The
format's grammar is C<header = v1-line 1*stanza end> -- one or more stanzas,
with no upper bound -- and neither reference implementation enforces one.

It exists because none of a header can be authenticated before it is paid for.
The header MAC key is derived from the file key, and the file key does not
exist until a stanza has been unwrapped, so L</unwrap_file_key> must try every
identity against every stanza -- an X25519 scalar multiplication, an HKDF and
a ChaCha20-Poly1305 open for each pair -- on a header nobody has vouched for
yet. 98 bytes of attacker-controlled header therefore buy a scalar
multiplication, and the cost is linear in stanzas times identities
(CVE-2026-85783, fixed in 0.004).

The default is C<128>. That is a maintainer decision rather than a property of
the format: the upstream test kit tops out at three stanzas and real files
carry a handful, but C<age -R> writes a 300-recipient file without complaint,
and such a file decrypts correctly here. B<This limit therefore rejects files
that a reference implementation produces.> A caller who has one raises the
limit:

    Crypt::Age->decrypt_file(
        input       => $many_recipients,
        output      => $plaintext,
        identities  => \@identities,
        max_stanzas => 512,
    );

C<max_stanzas> must be a positive integer. Omitting it means the default;
C<undef> and C<0> are errors rather than "no limit", since C<0> read literally
means "allow zero stanzas" -- which the grammar forbids anyway -- and a limit
that a falsy value switches off silently is one that disappears exactly when a
caller computes it and the computation goes wrong. To read headers the way
C<age> does, pass a number large enough to say so.

The limit is applied while the header is being read, at the start line of the
first stanza over it, so the rest of the header is never read and none of its
stanzas are ever tried.

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
