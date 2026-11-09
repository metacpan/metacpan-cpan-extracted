package DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder;
# ABSTRACT: EWKB-hex decoder for PostGIS geometry values

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Carp;
use DBIO::Exception;


# The type ids PostGIS writes into the type word of an EWKB, as read off
# a PostGIS 3.6 server. t/34-undecoded-live.t holds the names from 8 on
# against the server it runs on.
my %WKB_TYPES = (
  1 => 'point', 2 => 'linestring', 3 => 'polygon',
  4 => 'multipoint', 5 => 'multilinestring', 6 => 'multipolygon',
  7 => 'geometrycollection',
  8 => 'circularstring', 9 => 'compoundcurve', 10 => 'curvepolygon',
  11 => 'multicurve', 12 => 'multisurface',
  15 => 'polyhedralsurface', 16 => 'tin', 17 => 'triangle',
);

# The types whose body is decoded. Every other one is named, if it has a
# name, and its body is left alone.
my %DECODED = map { $_ => 1 } 1 .. 7;

# What the members of a MULTI* are. A GEOMETRYCOLLECTION takes any type.
my %MEMBER_TYPE = (4 => 1, 5 => 2, 6 => 3);

# Collections nest at most this deep; the outermost counts as level 1.
my $MAX_DEPTH = 32;

my $SRID_FLAG = 0x20000000;
my $Z_FLAG    = 0x80000000;
my $M_FLAG    = 0x40000000;


sub decode_hex {
  my ($class, $hex) = @_;
  my $bin = _unhex($hex);
  my $len = length($bin);
  my $pos = 0;

  my ($header, $le, $type_id) = _read_header(\$bin, \$pos, $len);
  my $coords = _read_geometry(
    \$bin, \$pos, $le, $type_id, $header->{has_z}, $header->{has_m}, $len, 0,
  );

  # Where an undecoded body ends is not known, so only a decoded value
  # can have bytes left behind it.
  DBIO::Exception->throw(
    "decode_hex: trailing bytes at pos $pos (" . ($len - $pos) . " after the geometry)"
  ) if defined $coords && $pos < $len;

  # Nothing is known about a body that is not decoded, empty or not.
  my $is_empty = defined $coords ? _is_empty($type_id, $coords) : undef;

  return { %$header, coords => $coords, is_empty => $is_empty };
}


sub decode_header {
  my ($class, $hex) = @_;
  my $bin = _unhex($hex);
  my $pos = 0;
  my ($header) = _read_header(\$bin, \$pos, length($bin));
  return $header;
}

# The bytes of a hex string. pack('H*') takes anything: it pads a lone
# last nibble with zero and reads any other character as a digit, so a cut
# off or damaged string came out as a shifted, wrong geometry.
sub _unhex {
  my ($hex) = @_;
  DBIO::Exception->throw('decode_hex: input is not hex (odd length or a non-hex character)')
    unless $hex =~ /\A(?:[0-9A-Fa-f]{2})*\z/;
  return pack('H*', $hex);
}

# The header, and what the body reader needs to go on: the byte order and
# the numeric type.
sub _read_header {
  my ($buf, $pos, $len) = @_;

  DBIO::Exception->throw('decode_hex: empty input') unless $len > 0;

  my $byte_order = _read_uint8($buf, $pos, $len);
  DBIO::Exception->throw("decode_hex: invalid byte_order") unless $byte_order == 1 || $byte_order == 0;
  my $le = ($byte_order == 1);

  my $type_raw = _read_uint32($buf, $pos, $le, $len);
  my $has_srid = ($type_raw & $SRID_FLAG) ? 1 : 0;
  my $has_z    = ($type_raw & $Z_FLAG)    ? 1 : 0;
  my $has_m    = ($type_raw & $M_FLAG)    ? 1 : 0;
  my $type_id  = $type_raw & 0xFFFF;

  my $srid;
  if ($has_srid) {
    $srid = _read_uint32($buf, $pos, $le, $len);
  }

  my $header = {
    type => $WKB_TYPES{$type_id}, srid => $srid, has_z => $has_z, has_m => $has_m,
  };
  return ($header, $le, $type_id);
}

sub _check_bounds {
  my ($buf, $pos, $need, $len) = @_;
  DBIO::Exception->throw(
    "decode_hex: underrun at pos $$pos (need $need, have " . ($len - $$pos) . ")"
  ) if $$pos + $need > $len;
}

sub _read_uint8 {
  my ($buf, $pos, $len) = @_;
  _check_bounds($buf, $pos, 1, $len);
  my $v = unpack('C', substr($$buf, $$pos, 1));
  $$pos += 1; $v;
}
sub _read_uint32 {
  my ($buf, $pos, $le, $len) = @_;
  _check_bounds($buf, $pos, 4, $len);
  my $v = unpack($le ? 'V' : 'N', substr($$buf, $$pos, 4));
  $$pos += 4; $v;
}
sub _read_double {
  my ($buf, $pos, $le, $len) = @_;
  _check_bounds($buf, $pos, 8, $len);
  my $v = unpack($le ? 'd<' : 'd>', substr($$buf, $$pos, 8));
  $$pos += 8; $v;
}

# The point of a POINT, or of a MULTIPOINT or a collection: PostGIS writes
# POINT EMPTY as a point of NaN ordinates. That is no point; its
# coordinates are an empty list. (A point in a line is read by _read_point
# and is never empty.)
sub _read_geometry_point {
  my ($c) = @_;
  return [] if @$c >= 2 && $c->[0] != $c->[0] && $c->[1] != $c->[1];
  return $c;
}

sub _read_point {
  my ($buf, $pos, $le, $has_z, $has_m, $len) = @_;
  my @c = (_read_double($buf, $pos, $le, $len), _read_double($buf, $pos, $le, $len));
  push @c, _read_double($buf, $pos, $le, $len) if $has_z;
  push @c, _read_double($buf, $pos, $le, $len) if $has_m;
  return \@c;
}

# A count of things that follow, each of them at least $min bytes long. A
# count the rest of the input cannot hold is refused here, before a list
# is sized by it: the four bytes are input like any other, and a list of
# 0xFFFFFFFF elements is the end of the process, not an exception.
sub _read_count {
  my ($buf, $pos, $le, $len, $min) = @_;
  my $n = _read_uint32($buf, $pos, $le, $len);
  _check_bounds($buf, $pos, $n * $min, $len);
  return $n;
}

# The coordinates of the geometry at $pos, or undef for one that is not
# decoded. undef is not an error and says nothing about the bytes; it has
# to reach the caller as it is, so nothing here may go on reading after
# it -- where an undecoded body ends is not known.
sub _read_geometry {
  my ($buf, $pos, $le, $type_id, $has_z, $has_m, $len, $depth) = @_;
  return undef unless $DECODED{$type_id};

  DBIO::Exception->throw('decode_hex: nesting too deep')
    if $type_id == 7 && ++$depth > $MAX_DEPTH;

  if ($type_id == 1) {
    return _read_geometry_point(_read_point($buf, $pos, $le, $has_z, $has_m, $len));
  }
  my $point_size = 8 * (2 + $has_z + $has_m);
  if ($type_id == 2) {
    my $n = _read_count($buf, $pos, $le, $len, $point_size);
    return [ map { _read_point($buf, $pos, $le, $has_z, $has_m, $len) } 1..$n ];
  }
  if ($type_id == 3) {
    # A ring is at least its own count.
    my $n = _read_count($buf, $pos, $le, $len, 4);
    my @rings;
    for (1..$n) {
      my $m = _read_count($buf, $pos, $le, $len, $point_size);
      push @rings, [ map { _read_point($buf, $pos, $le, $has_z, $has_m, $len) } 1..$m ];
    }
    return \@rings;
  }

  # Members, each with a header of its own: byte order and type word. A
  # MULTI* holds their coordinates, a collection the members themselves,
  # with their type.
  my $n = _read_count($buf, $pos, $le, $len, 5);
  my @members;
  for (1..$n) {
    my ($member_type, $member) = _read_subgeom(
      $buf, $pos, $le, $MEMBER_TYPE{$type_id}, $has_z, $has_m, $len, $depth,
    );
    return undef unless defined $member;
    push @members, $type_id == 7
      ? { type => $WKB_TYPES{$member_type}, coords => $member,
          is_empty => _is_empty($member_type, $member) }
      : $member;
  }
  return \@members;
}

# Empty as ST_IsEmpty says: no parts, or nothing but empty ones. $coords
# is that of a decoded geometry; an empty point is [], a point is never a
# list of parts.
sub _is_empty {
  my ($type_id, $coords) = @_;
  return @$coords ? 0 : 1 if $type_id == 1 || $type_id == 2 || $type_id == 3;
  return (grep { @$_ } @$coords) ? 0 : 1 if $type_id >= 4 && $type_id <= 6;
  return (grep { !$_->{is_empty} } @$coords) ? 0 : 1;
}

# One member of a MULTI* or of a collection: its type id and its
# coordinates (undef if it is not decoded). $expect is the type a MULTI*
# takes; a collection passes none and takes them all. A member has a
# header of its own: it is read in its own byte order, not that of the
# whole, and its Z and M flags are those of the whole or the value is
# refused, as PostGIS does ("Dimensions mismatch in lwcollection"). PostGIS
# writes no SRID into a member; one that is there is read and dropped.
sub _read_subgeom {
  my ($buf, $pos, $le, $expect, $has_z, $has_m, $len, $depth) = @_;
  my $start = $$pos;
  my $byte_order = _read_uint8($buf, $pos, $len);
  DBIO::Exception->throw("decode_hex: invalid byte_order") unless $byte_order == 1 || $byte_order == 0;
  $le = ($byte_order == 1);
  my $type_raw = _read_uint32($buf, $pos, $le, $len);
  my $type_id  = $type_raw & 0xFFFF;
  _read_uint32($buf, $pos, $le, $len) if $type_raw & $SRID_FLAG;
  DBIO::Exception->throw(
    "decode_hex: member of type $type_id at pos $start"
      . ", where only type $expect can be"
  ) if defined $expect && $type_id != $expect;
  DBIO::Exception->throw(
    "decode_hex: member at pos $start has other dimensions than the whole"
  ) if (($type_raw & $Z_FLAG) ? 1 : 0) != $has_z || (($type_raw & $M_FLAG) ? 1 : 0) != $has_m;
  return ($type_id, _read_geometry($buf, $pos, $le, $type_id, $has_z, $has_m, $len, $depth));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder - EWKB-hex decoder for PostGIS geometry values

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Reads the hex-encoded EWKB PostGIS sends for a C<geometry> or
C<geography> value. An input has one of three outcomes:

=over 4

=item *

B<Decoded.> The types C<point>, C<linestring>, C<polygon>,
C<multipoint>, C<multilinestring>, C<multipolygon> and
C<geometrycollection> are decoded to their coordinates, and to whether
they are empty.

=item *

B<Named, not decoded.> PostGIS writes more types than those:
C<circularstring>, C<compoundcurve>, C<curvepolygon>, C<multicurve>,
C<multisurface>, C<polyhedralsurface>, C<tin> and C<triangle>. Their
header is read, their body is not, and L</decode_hex> returns C<coords>
as C<undef>. So it does for a C<geometrycollection> that holds a member
of such a type, at any depth -- a collection is decoded as a whole or
not at all -- and for a type id that has no name here, whose C<type> is
C<undef> as well. No coordinates are returned for bytes this decoder
does not know the layout of.

=item *

B<Refused.> Input that is no EWKB -- not hex (a character that is no hex
digit, or an odd number of them), empty, a byte order that is neither 0
nor 1 (in the header or in a member), cut off, a count the rest of the
input cannot hold, bytes left over behind the end of a decoded geometry,
a C<multipoint> whose member is not a point, a member whose Z or M flag
differs from that of the whole, a C<geometrycollection> nested deeper
than 32 levels (the outermost is level 1) -- throws a L<DBIO::Exception>.
L</decode_header> tells what the header of such an input says, if it has
one (not for input that is not hex).

=back

PostGIS does not send input of the third kind: a value read from a
database is decoded, or named and left alone.

=head1 METHODS

=head2 decode_hex

    my $result = DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder->decode_hex($hex);

Decodes an EWKB hex string into a hashref:

    {
      type   => 'point',
      srid   => 4326,       # undef if not present
      has_z  => 0,
      has_m  => 0,
      coords => [x, y],     # nested for non-point types
      is_empty => 0,
    }

C<coords> is C<undef> for a value that is not decoded (see
L</DESCRIPTION>); C<type>, C<srid>, C<has_z> and C<has_m> are those of
its header all the same. C<type> is C<undef> for a type id that has no
name here. Throws for input that is refused.

C<is_empty> is true for what PostGIS calls empty (C<ST_IsEmpty>): a
geometry without parts -- a C<linestring> or C<polygon> with no points or
rings, a C<multi*> or C<geometrycollection> with no members -- a C<point>
whose X and Y are both NaN (this is how PostGIS writes C<POINT EMPTY>),
and a C<multi*> or C<geometrycollection> whose members are all empty,
C<MULTIPOINT(EMPTY)> for one. C<coords> of an empty geometry is C<[]>,
and so is that of an empty point: not C<[NaN, NaN]>. A point with just
one NaN ordinate is a point. C<is_empty> is C<undef>, not false, for a
value that is not decoded: nothing is known about it.

An empty member of a C<multi*> keeps its place in C<coords> as an empty
list: C<MULTIPOINT(EMPTY,(1 2))> is C<[[], [1,2]]>. The structure of a
C<multi*> is otherwise the plain coordinates of its parts.

B<The members of a C<geometrycollection>> are a list of hashes, one per
member, in order, each carrying what the whole has:

    {
      type     => 'linestring',   # any decoded type, a collection too
      coords   => [[0,0],[1,1]],  # as for that type; a collection's
                                  # coords are again such a list
      is_empty => 0,              # that of the member
    }

The members are returned with their types, not as bare coordinates, so the
geometry and a valid WKT can be told from them. The Z and M flags of a member
are those of the whole, the decoder refuses a member that differs.

What is read, and what is not, where PostGIS (C<ST_GeomFromEWKB>, checked
against 3.6) is more lenient than this decoder or the other way round:

=over 4

=item *

Both byte orders are read, and so are the members of a C<MULTI*> or a
collection in a byte order of their own: a big-endian member in a
little-endian value is read as big-endian, as PostGIS does. Nothing but
0 and 1 is a byte order.

=item *

A member with an SRID flag: PostGIS never writes one, but accepts it and
drops it; the SRID of the geometry is that of the outer header. The
decoder reads the SRID word of the member and drops it as well.

=item *

A member must have the Z and M flags of the whole. PostGIS refuses
anything else ("Dimensions mismatch in lwcollection"); so does the
decoder, which would otherwise read the member at the wrong width.

=item *

Bytes left behind the end of a decoded geometry are refused ("trailing
bytes"). PostGIS ignores them; but a value it sends has none, so they
mean the input is not what it claims to be. For a value that is not
decoded the end of the body is not known, and nothing is checked.

=item *

The hex must be hex: pairs of digits, either case, nothing else -- no
C<0x> prefix, no whitespace.

=item *

ISO WKB type codes (1001 for C<POINT Z>, 2001 for C<POINT M>, 3001 for
C<POINT ZM> and so on) are B<not> read. PostGIS understands them when it
is given them, but never sends them: it writes EWKB, with the dimension
in the flags. The decoder masks the type word with C<0xFFFF>, so such a
code is a type id without a name, and the value is returned as one:
C<type> and C<coords> are C<undef>.

=back

=head2 decode_header

    my $header = DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder->decode_header($hex);

Reads the header of an EWKB hex string -- byte order, type word, SRID --
and nothing after it. Returns what L</decode_hex> returns, without
C<coords>:

    { type => 'point', srid => 4326, has_z => 0, has_m => 0 }

This is what there is to say about an input L</decode_hex> refuses for
its body. Throws if the header itself cannot be read, with the message
L</decode_hex> throws for it.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
