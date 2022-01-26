package Data::ULID;

use strict;
use warnings;

our $VERSION = '1.1.2';

use base qw(Exporter);
our @EXPORT_OK = qw/ulid binary_ulid ulid_date ulid_to_uuid uuid_to_ulid/;
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

use Time::HiRes qw/time/;
use Math::BigInt 1.999808 try => 'GMP,LTM';
use Crypt::PRNG qw/random_bytes/;
use DateTime;

use Config;
our $CAN_SKIP_BIGINTS = $Config{ivsize} >= 8;

### EXPORTED ULID FUNCTIONS

sub ulid {
    return _encode(_ulid(shift));
}

sub binary_ulid {
    return _pack(_ulid(shift));
}

sub ulid_date {
    my $ulid = shift;
    die "ulid_date() needs a normal or binary ULID as parameter" unless $ulid;
    my ($ts, $rand) = _ulid($ulid);

    return DateTime->from_epoch(epoch => _unfix_ts($ts));
}

sub ulid_to_uuid {
    my $ulid = shift or die "Need ULID to convert";
    my $bin = _pack(_ulid($ulid));
    return _uuid_bin2str($bin)
}

sub uuid_to_ulid {
    my $uuid = shift or die "Need UUID to convert";
    my $bin_uuid = _uuid_str2bin($uuid);
    return _encode(_ulid($bin_uuid));
}

### HELPER FUNCTIONS

sub _uuid_bin2str {
    my $uuid = shift;

    return $uuid if length($uuid) == 36;
    die "Invalid uuid" unless length $uuid == 16;
    my @offsets = (4, 2, 2, 2, 6);

    return join(
        '-',
        map { unpack 'H*', $_ }
        map { substr $uuid, 0, $_, ''}
        @offsets);
}

sub _uuid_str2bin {
    my $uuid = shift;

    return $uuid if length $uuid == 16;
    $uuid =~ s/-//g;

    return pack 'H*', $uuid;
}

sub _ulid {
    my $arg = shift;
    my $ts;

    if ($arg) {
        if (ref $arg && $arg->isa('DateTime')) {
            $ts = $arg->hires_epoch;
        }
        elsif (length($arg) == 16) {
            return _unpack($arg);
        }
        else {
            $arg = _normalize($arg);
            die "Invalid ULID supplied: wrong length" unless length($arg) == 26;
            return _decode($arg);
        }
    }

    return (_fix_ts($ts || time()), random_bytes(10));
}

sub _pack {
    my ($ts, $rand) = @_;
    return _zero_pad($ts, 6, "\x00") . _zero_pad($rand, 10, "\x00");
}

sub _unpack {
    my ($ts, $rand) = unpack 'a6a10', shift;
    return ($ts, $rand);
}

sub _fix_ts {
    my $ts = shift;

    if ($CAN_SKIP_BIGINTS) {
        $ts *= 1000;
        return pack 'Nn', int($ts / (2 << 15)), $ts % (2 << 15);
    } else {
        $ts .= '000';
        $ts =~ s/\.(\d{3}).*$/$1/;
        return Math::BigInt->new($ts)->to_bytes;
    }
}

sub _unfix_ts {
    my $ts = shift;

    if ($CAN_SKIP_BIGINTS) {
        my ($high, $low) = unpack 'Nn', $ts;
        return ($high * (2 << 15) + $low) / 1000;
    } else {
        $ts = Math::BigInt->from_bytes($ts);
        $ts =~ s/(\d{3})$/.$1/;
        return $ts;
    }
}

sub _encode {
    my ($ts, $rand) = @_;
    return sprintf('%010s%016s', _encode_b32($ts), _encode_b32($rand));
}

sub _decode {
    my ($ts, $rand) = map { _decode_b32($_) } unpack 'A10A16', shift;
    return ($ts, $rand);
}

sub _zero_pad {
    my ($value, $mul, $char) = @_;
    $char ||= '0';

    while ($char eq substr $value, 0, 1) { substr $value, 0, 1, '' }

    my $left = $mul - length($value) % $mul;
    return $char x ($left % $mul) . $value;
}

### BASE32 ENCODER / DECODER

my $ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

my %ALPHABET_MAP = do {
    my $num = 0;
    map { $_ => substr sprintf('0000%b', $num++), -5 } split //, $ALPHABET;
};

my %ALPHABET_MAP_REVERSE = map { $ALPHABET_MAP{$_} => $_ } keys %ALPHABET_MAP;

sub _normalize {
    my $s = uc(shift);
    my $re = "[^$ALPHABET]";

    $s =~ s/$re//g;
    return $s;
}

sub _encode_b32 {
    my $bits = unpack 'B*', shift;
    $bits = _zero_pad($bits, 5);

    my $result = '';
    for (my $i = 0; $i < length $bits; $i += 5) {
        $result .= $ALPHABET_MAP_REVERSE{substr $bits, $i, 5};
    }
    return $result;
}

sub _decode_b32 {
    my $encoded = join '', map { $ALPHABET_MAP{uc $_} } split //, shift;
    return pack 'B*', _zero_pad($encoded, 8);
}

1;

__END__

=pod

=head1 NAME

Data::ULID - Universally Unique Lexicographically Sortable Identifier


=head1 SYNOPSIS

 use Data::ULID qw/ulid binary_ulid ulid_date/;

 my $ulid = ulid();  # e.g. 01ARZ3NDEKTSV4RRFFQ69G5FAV
 my $bin_ulid = binary_ulid($ulid);
 my $datetime_obj = ulid_date($ulid);  # e.g. 2016-06-13T13:25:20
 my $uuid = ulid_to_uuid($ulid);
 my $ulid2 = uuid_to_ulid($uuid);


=head1 DESCRIPTION

=head2 Background

This is an implementation in Perl of the ULID identifier type introduced by
Alizain Feerasta. The original implementation (in Javascript) can be found at
L<https://github.com/alizain/ulid>.

ULIDs have several advantages over UUIDs in many contexts. The advantages
include:

=over

=item *

Lexicographically sortable

=item *

The canonical representation is shorter than UUID (26 vs 36 characters)

=item *

Case insensitve and safely chunkable.

=item *

URL-safe

=item *

Timestamp can always be easily extracted if so desired.

=item *

Limited compatibility with UUIDS, since both are 128-bit formats.
Some conversion back and forth is possible.

=back

=head2 Canonical representation

The canonical representation of a ULID is a 26-byte, base32-encoded string
consisting of (1) a 10-byte timestamp with millisecond-resolution; and (2) a
16-byte random part.

Without paramters, the C<ulid()> function returns a new ULID in the canonical
representation, with the current time (up to the nearest millisecond) in the
timestamp part.

 $ulid = ulid();

Given a DateTime object as parameter, the function will set the timestamp part
based on that:

 $ulid = ulid($datetime_obj);

Given a binary ULID as parameter, it returns the same ULID in canonical
format:

 $ulid = ulid($binary_ulid);

=head2 Binary representation

The binary representation of a ULID is 16 octets long, with each component in
network byte order (most significant byte first). The components are (1) a
48-bit (6-byte) timestamp in a 32-bit and a 16-bit chunk; (2) an 80-bit
(10-byte) random part in a 16-bit and two 32-bit chunks.

The C<binary_ulid()> function returns a ULID in binary representation. Like
C<ulid()>, it can take no parameters or a DateTime, but it can also take a
ULID in the canonical representation and convert it to binary:

 $binary_ulid = binary_ulid($canonical_ulid);

=head2 Datetime extraction

The C<ulid_date()> function takes a ULID (canonical or binary) and returns
a DateTime object corresponding to the timestamp it encodes.

 $datetime = ulid_date($ulid);

=head2 UUID conversion

Very limited conversion between UUIDs and ULIDs is provided.

In order to convert a UUID to ULID:

 $ulid = uuid_to_ulid($uuid);

Both binary and hexadecimal UUIDs (with or without separators) are accepted.
The return value is a ULID string in the canonical Base32 form. Note that the
"timestamp" of such a ULID is not to be relied upon.

A ULID can also be converted to a UUID:

 $uuid = ulid_to_uuid($binary_or_canonical_ulid);

The UUID returned by this function is a string in the standard hyphenated
hexadecimal format. Note that the variant and version indicators of such a
UUID are meaningless.

=head2 UUID conversion limitations

Since both ULIDs and UUIDs are 128-bit, conversion back and forth is possible
in principle. However, the two formats have different semantics. Also, any
given UUID version has at most 122 bits of variance (4 bits being reserved as
variant and version indicators), while all 128 bits of the ULID format can
vary without violating the format description. This means that the conversion
can never be made perfect.

It would be possible to maintain the approximate timestamp of a Version 1 UUID
when converting to ULID, as well as to keep the timestamp of a ULID when
converting to UUID. However, since many UUIDs are not of Version 1, and given
the different semantics of the two formats, the conversion provided by this
module is much simpler and does not preserve the timestamps. In fact, about
the only desirable property that the chosen conversion method has is that it
is uniformly bidirectional, i.e.

 $uuid eq ulid_to_uuid(ulid_to_uuid($uuid))

and

 $ulid eq uuid_to_ulid(ulid_to_uuid($ulid))

This approach has two immediate consequences:

=over

=item 1.

The "timestamps" of ULIDs created by converting UUIDs are meaningless.

=item 2.

The variant and version indicators of UUIDs created by converting ULIDs are
similarly wrong. Such UUIDs should only be used in contexts where no checking
of these fields will be performed and no attempt will be made to extract or
validate non-random information (i.e. timestamp, MAC address or namespace).

=back


=head1 DEPENDENCIES

L<Math::Random::Secure>, L<Encode::Base32::GMP>.


=head1 AUTHOR

Baldur Kristinsson, December 2016


=head1 LICENSE

This is free software. It may be copied, distributed and modified under the
same terms as Perl itself.


=head1 VERSION HISTORY

 0.1   - Initial version.
 0.2   - Bugfixes: (a) fix errors on Perl 5.18 and older, (b) address an issue
         with GMPz wrt Math::BigInt objects.
 0.3   - Bugfix: Try to prevent 'Inappropriate argument' error from pre-0.43
         versions of Math::GMPz.
 0.4   - Bugfix: 'Invalid argument supplied to Math::GMPz::overload_mod' for
         older versions of Math::GMPz on Windows and FreeBSD. Podfix.
 1.0.0 - UUID conversion support; semantic versioning.
 1.1.0 - Speedups courtesy of Bartosz Jarzyna (brtastic on CPAN, bbrtj on
         Github). Use Crypt::PRNG for random number generation.
 1.1.1 - Fix module version number.
 1.1.2 - Fix POD (version history).

=cut
