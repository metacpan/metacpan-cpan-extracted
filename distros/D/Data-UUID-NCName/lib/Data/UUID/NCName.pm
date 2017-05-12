package Data::UUID::NCName;

use 5.008;
use strict;
use warnings FATAL => 'all';

use MIME::Base32 ();
use MIME::Base64 ();
use Carp ();

use base qw(Exporter);

=head1 NAME

Data::UUID::NCName - Make valid NCName tokens which are also UUIDs

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Data::UUID::NCName qw(:all);

    my $uuid  = '1ff916f3-6ed7-443a-bef5-f4c85f18cd10';
    my $ncn   = to_ncname($uuid);
    my $ncn32 = to_ncname($uuid, 32);

    # $ncn is now "EH_kW827XQ6vvX0yF8YzRA".
    # $ncn32 is "Ed74rn43o25b2x327jsc7ddgra" and case-insensitive.

    # from Test::More, this will output 'ok':
    is(from_ncname($ncn), $uuid, 'Decoding result matches original');

=head1 DESCRIPTION

The purpose of this module is to devise an alternative representation
of the L<UUID|http://tools.ietf.org/html/rfc4122> which conforms to
the constraints of various other identifiers such as NCName, and create an
L<isomorphic|http://en.wikipedia.org/wiki/Isomorphism> mapping between
them.

=head1 RATIONALE & METHOD

The UUID is a generic identifier which is large enough to be globally
unique. This makes it useful as a canonical name for data objects in
distributed systems, especially those that cross administrative
jurisdictions, such as the World-Wide Web. The
L<representation|http://tools.ietf.org/html/rfc4122#section-3>,
however, of the UUID, precludes it from being used in many places
where it would be useful to do so.

In particular, there are grammars for many types of identifiers which
must not begin with a digit. Others are case-insensitive, or
prohibited from containing hyphens (present in both the standard
notation and Base64URL), or indeed anything outside of
C<^[A-Za-z_][0-9A-Za-z_]*$>.

The hexadecimal notation of the UUID has a 5/8 chance of beginning
with a digit, Base64 has a 5/32 chance, and Base32 has a 3/16
chance. As such, the identifier must be modified in such a way as to
guarantee beginning with an alphabetic letter (or underscore C<_>, but some
grammars even prohibit that, so we omit it as well).

While it is conceivable to simply add a padding character, there are a
few considerations which make it more appealing to derive the initial
character from the content of the UUID itself:

=over 4

=item *

UUIDs are large (128-bit) identifiers as it is, and it is undesirable
to add meaningless syntax to them if we can avoid doing so.

=item *

128 bits is an inconvenient number for aligning to both Base32 (130)
and Base64 (132), though 120 divides cleanly into 5, 6 and 8.

=item *

The 13th quartet, or higher four bits of the
C<time_hi_and_version_field> of the UUID is constant, as it indicates
the UUID's version. If we encode this value using the scheme common to
both Base64 and Base32, we get values between C<A> and C<P>, with the
valid subset between C<B> and C<F>.

=back

B<Therefore:> extract the UUID's version quartet, shift all subsequent
data 4 bits to the left, zero-pad to the octet, encode with either
I<base64url> or I<base32>, truncate, and finally prepend the encoded
version character. VoilE<agrave>, one token-safe UUID.

=head1 APPLICATIONS

=over 4

=item XML IDs

The C<ID> production appears to have been constricted, inadvertently
or otherwise, from L<Name|http://www.w3.org/TR/xml11/#NT-Name> in both
the XML 1.0 and 1.1 specifications, to
L<NCName|http://www.w3.org/TR/xml-names/#NT-NCName> by L<XML Schema
Part 2|http://www.w3.org/TR/xmlschema-2/#ID>. This removes the colon
character C<:> from the grammar. The net effect is that

    <foo id="urn:uuid:b07caf81-baae-449d-8a2e-48c0f5fa5538"/>

while being a I<well-formed> ID I<and> valid under DTD validation, is
I<not> valid per XML Schema Part 2 or anything that uses it
(e.g. Relax NG).

=item RDF blank node identifiers

Blank node identifiers in RDF are intended for serialization, to act
as a handle so that multiple RDF statements can refer to the same
blank node. The L<RDF abstract syntax
specifies|http://www.w3.org/TR/rdf-concepts/#section-URI-Vocabulary>
that the validity constraints of blank node identifiers be delegated
to the concrete syntax specifications. The L<RDF/XML syntax
specification|http://www.w3.org/TR/rdf-syntax-grammar/#rdf-id>
lists the blank node identifier as NCName. However, according to
L<the Turtle spec|http://www.w3.org/TR/turtle/#BNodes>, this is a
valid blank node identifier:

    _:42df00ec-30a2-431f-be9e-e3a612b325db

despite L<an older
version|http://www.w3.org/TeamSubmission/turtle/#nodeID> listing a
production equivalent to the more conservative NCName. NTriples
syntax is L<even more
constrained|http://www.w3.org/TR/rdf-testcases/#ntriples>, given as
C<^[A-Za-z][0-9A-Za-z]*$>.

=item Generated symbols

=over 4

There are only two hard things in computer science: cache
invalidation and naming things [and off-by-one errors].

-- Phil Karlton [extension of unknown origin]

=back

Suppose you wanted to create a L<literate
programming|http://en.wikipedia.org/wiki/Literate_programming> system
(I do). One of your (my) stipulations is that the symbols get defined
in the I<prose>, rather than the I<code>. However, you (I) still want
to be able to validate the code's syntax, and potentially even run the
code, without having to commit to naming anything. You are (I am) also
interested in creating a global map of classes, datatypes and code
fragments, which can be operated on and tested in isolation, ported to
other languages, or transplanted into the more conventional packages
of programs, libraries and frameworks. The Base32 UUID NCName
representation should be adequate for placeholder symbols in just
about any programming language, save for those which do not permit
identifiers as long as 26 characters (which are extremely scarce).

=back

=head1 EXPORT

No subroutines are exported by default. Be sure to include at least
one of the following in your C<use> statement:

=over 4

=item :all

Import all functions.

=item :decode

Import decode-only functions.

=item :encode

Import encode-only functions.

=item :32

Import base32-only functions.

=item :64

Import base64-only functions.

=back

=cut

# exporter stuff

our %EXPORT_TAGS = (
    all => [qw(to_ncname from_ncname
               to_ncname_32 from_ncname_32
               to_ncname_64 from_ncname_64)],
    decode => [qw(from_ncname from_ncname_32 from_ncname_64)],
    encode => [qw(to_ncname to_ncname_32 to_ncname_64)],
    32     => [qw(to_ncname_32 from_ncname_32)],
    64     => [qw(to_ncname_64 from_ncname_64)],
);

# export nothing by default
our @EXPORT = ();
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

# uuid format string, so meta.
my $UUF = sprintf('%s-%s-%s-%s-%s', '%02x' x 4, ('%02x' x 2) x 3, '%02x' x 6);
# yo dawg i herd u liek format strings so we put a format string in yo
# format string

# dispatch tables for encoding/decoding

my %ENCODE = (
    32 => sub {
        my @in = unpack 'C*', shift;
        $in[-1] >>= 1;
        my $out = MIME::Base32::encode_rfc3548(pack 'C*', @in);

        # we want lower case because IT IS RUDE TO SHOUT
        lc substr($out, 0, 25);
    },
    64 => sub {
        my @in = unpack 'C*', shift;
        #warn $in[-1] >> 2;
        $in[-1] >>= 2;
        my $out = MIME::Base64::encode(pack 'C*', @in);
        # note that the rfc4648 sequence ends in +/ or -_
        $out =~ tr!+/!-_!;

        substr($out, 0, 21);
    },
);

my %DECODE = (
    32 => sub {
        my $in = shift;
        $in = uc substr($in, 0, 25) . '0';

        my @out = unpack 'C*', MIME::Base32::decode_rfc3548($in);
        $out[-1] <<= 1;

        pack 'C*', @out;
    },
    64 => sub {
        my $in = shift;
        #warn $in;
        $in = substr($in, 0, 21) . 'A==';
        # note that the rfc4648 sequence ends in +/ or -_
        $in =~ tr!-_!+/!;

        #warn unpack 'H*', MIME::Base64::decode($in);

        my @out = unpack 'C*', MIME::Base64::decode($in);

        $out[-1] <<= 2;

        pack 'C*', @out;
    },
);

sub _bin_uuid_to_pair {
    my $data = shift;
    my @list = unpack 'N4', $data;

    my $ver = ($list[1] & 0x0000f000) >> 12;
    $list[1] = ($list[1] & 0xffff0000) |
        (($list[1] & 0x00000fff) << 4) | ($list[2] >> 28);
    $list[2] = ($list[2] & 0x0fffffff) << 4 | ($list[3] >> 28);
    $list[3] <<= 4;

    return $ver, pack 'N4', @list;
}

sub _pair_to_bin_uuid {
    my ($ver, $data) = @_;

    $ver &= 0xf;

    my @list = unpack 'N4', $data;

    $list[3] >>= 4;
    $list[3] |= (($list[2] & 0xf) << 28);
    $list[2] >>= 4;
    $list[2] |= (($list[1] & 0xf) << 28);
    $list[1] =
        ($list[1] & 0xffff0000) | ($ver << 12) | (($list[1] >> 4) & 0xfff);

    #warn unpack 'H*', pack 'N4', @list;

    pack 'N4', @list;
}

sub _encode_version {
    my $ver = $_[0] & 15;
    # A (0) starts at 65. this should never be higher than F (version
    # 5) for a valid UUID, but even an invalid one will never be
    # higher than P (15).

    # XXX boo-hoo, this will break in EBCDIC.
    chr($ver + 65);
}

sub _decode_version {
    # modulo makes sure this always returns between 0 and 15
    return((ord(uc $_[0]) - 65) % 16);
}

=head1 SUBROUTINES

=head2 to_ncname $UUID [, $RADIX ]

Turn C<$UUID> into an NCName. The UUID can be in the canonical
(hyphenated) hexadecimal form, non-hyphenated hexadecimal, Base64
(regular and base64url), or binary. The function returns a legal
NCName equivalent to the UUID, in either Base32 or Base64 (url), given
a specified C<$RADIX> of 32 or 64. If the radix is omitted, Base64
is assumed.

=cut

sub to_ncname {
    my ($uuid, $radix) = @_;

    if ($radix) {
        Carp::croak("Radix must be either 32 or 64, not $radix")
              unless $radix == 32 || $radix == 64;
    }
    else {
        $radix = 64;
    }

    # get the uuid into a binary string
    my $bin;
    if (length $uuid == 16) {
        # this is already a binary string
        $bin = $uuid;
    }
    else {
        # get rid of any whitespace
        $uuid =~ s/\s+//g;

        # handle hexadecimal
        if ($uuid =~ /^[0-9A-Fa-f-]{32,}$/) {
            $uuid =~ s/-//g;
            #warn $uuid;
            $bin = pack 'H*', $uuid;
        }
        # handle base64
        elsif ($uuid =~ m!^[0-9A-Za-z=+/_-]$!) {
            # canonicalize first
            $uuid =~ tr!-_!+/!;
            $bin = MIME::Base64::decode($uuid);
        }
        else {
            Carp::croak("Couldn't figure out what to do with putative UUID.");
        }
    }


    # extract the version
    my ($version, $content) = _bin_uuid_to_pair($bin);
    #warn $version;

    # wah-lah.
    _encode_version($version) . $ENCODE{$radix}->($content);
}

=head2 from_ncname $NCNAME [, $FORMAT, $RADIX ]

Turn an appropriate C<$NCNAME> back into a UUID, where I<appropriate>,
unless overridden by C<$RADIX>, is defined beginning with one initial
alphabetic letter (A to Z, case-insensitive) followed by either:

=over 4

=item B<25> Base32 characters, or

=item B<21> Base64URL characters.

=back

The function will return C<undef> immediately if it cannot match
either of these patterns. Input past the 21-character mark (for
Base64) or 25-character mark (for Base32) is ignored.

This function returns a UUID of type C<$FORMAT>, which if left
undefined, must be one of the following:

=over 4

=item str

The canonical UUID format, like so:
C<33fcc995-5d10-477e-a9b4-c9cc405bbf04>. This is the default.

=item hex

The same thing, minus the hyphens.

=item b64

Base64.

=item bin

A binary string.

=back

=cut

my %FORMAT = (
    str => sub {
        sprintf $UUF, unpack 'C*', shift;
    },
    hex => sub {
        unpack 'H*', shift;
    },
    b64 => sub {
        my $x = MIME::Base64::encode(shift);
        $x =~ s/=+$//;
        $x;
    },
    bin => sub {
        shift;
    },
);

sub from_ncname {
    my ($ncname, $format, $radix) = @_;

    # handle formatter
    $format ||= 'str';
    Carp::croak("Invalid format $format") unless $FORMAT{$format};
    # reuse this variable because it doesn't get used for anything else
    $format = $FORMAT{$format};

    # obviously this must be defined
    return unless defined $ncname;

    # no whitespace
    $ncname =~ s/^\s*(.*?)\s*$/$1/;

    # note that the rfc4648 sequence ends in +/ or -_
    my ($version, $content) = ($ncname =~ /^([A-Za-z])([0-9A-Za-z_-]{21,})$/)
        or return;

    if ($radix) {
        Carp::croak("Radix must be either 32 or 64, not $radix")
              unless $radix == 32 || $radix == 64;
    }
    else {
        # detect what to do based on input
        my $len = length $ncname;
        if ($ncname =~ m![_-]!) {
            # containing these characters means base64url
            $radix = 64;
        }
        elsif ($len >= 26) {
            # if it didn't contain those characters and is this long
            $radix = 32;
        }
        elsif ($len >= 22) {
            $radix = 64;
        }
        else {
            # the regex above should ensure this is never reached.
            Carp::croak
                  ("Not sure what to do with an identifier of length $len.");
        }
    }

    # get this stuff back to canonical form
    $version = _decode_version($version);
    # warn $version;
    $content = $DECODE{$radix}->($content);
    # warn  unpack 'H*', $content;

    # reassemble the pair
    my $bin = _pair_to_bin_uuid($version, $content);

    # *now* format.
    $format->($bin);
}

=head2 to_ncname_64 $UUID

Shorthand for Base64 NCNames.

=cut

sub to_ncname_64 {
    to_ncname(shift, 64);
}

=head2 from_ncname_64 $NCNAME [, $FORMAT ]

Ditto.

=cut

sub from_ncname_64 {
    from_ncname(shift, shift, 64);
}

=head2 to_ncname_32 $UUID

Shorthand for Base32 NCNames.

=cut

sub to_ncname_32 {
    to_ncname(shift, 32);
}

=head2 from_ncname_32 $NCNAME [, $FORMAT ]

Ditto.

=cut

sub from_ncname_32 {
    from_ncname(shift, shift, 32);
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-uuid-ncname
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-UUID-NCName>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::UUID::NCName

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-UUID-NCName>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-UUID-NCName>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-UUID-NCName>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-UUID-NCName/>

=back

=head1 SEE ALSO

=over 4

=item L<Data::UUID>

=item L<OSSP::uuid>

=item L<RFC 4122|http://tools.ietf.org/html/rfc4122>

=item L<RFC 4648|http://tools.ietf.org/html/rfc4648>

=item L<Namespaces in XML|http://www.w3.org/TR/xml-names/#NT-NCName>
(NCName)

=item L<W3C XML Schema Definition Language (XSD) 1.1 Part 2:
Datatypes|http://www.w3.org/TR/xmlschema11-2/#ID> (ID)

=item L<RDF/XML Syntax Specification
(Revised)|http://www.w3.org/TR/rdf-syntax-grammar/#rdf-id>

=item L<Turtle|http://www.w3.org/TR/turtle/#BNodes>

=back

This module lives under the C<Data::> namespace for the purpose of
namespace hygiene. It I<does not> depend on L<Data::UUID> or any
other UUID modules.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0> .

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Data::UUID::NCName
