package DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser;
# ABSTRACT: WKT/EWKT parser for PostGIS geometry values

use strict;
use warnings;

use DBIO::Exception ();

our $VERSION = '0.900004';


# Collections nest at most this deep; the outermost counts as level 1.
my $MAX_DEPTH = 32;

# A number as WKT writes it: optional minus, digits with an optional
# fraction or a fraction alone, optional exponent.
my $NUMBER_RE = qr/\A-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\z/;

my $TYPE_RE = qr/geometrycollection|multilinestring|multipolygon|multipoint|linestring|polygon|point/i;

# Thrown by the helpers for text that is no geometry; parse turns it into
# undef and rethrows anything else.
my $UNREADABLE = "DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser: unreadable\n";
sub _unreadable { die $UNREADABLE }

sub parse {
  my ($class, $wkt) = @_;
  return undef unless defined $wkt;
  my $text = "$wkt";
  my $result = eval {
    my $g = _geometry(\$text, 0);
    $text =~ /\G\s*\z/ or _unreadable();
    $g;
  };
  if (my $err = $@) {
    return undef if !ref $err && $err eq $UNREADABLE;
    die $err;
  }
  return $result;
}

# The parser reads the one string through pos() and \G: every helper takes a
# reference to it, continues where the previous one stopped and leaves pos()
# behind its own token. Nothing is copied but the text of a coordinate list.

# One geometry at the position. $depth is the number of GEOMETRYCOLLECTIONs
# around it.
sub _geometry {
  my ($s, $depth) = @_;

  # The marker is glued to the type (POINTM) or a word of its own, never both.
  $$s =~ /\G\s*($TYPE_RE)(?:(ZM|Z|M)|\s+(ZM|Z|M))?\s*(\(|EMPTY)/gci
    or _unreadable();
  my ($type, $mark, $open) = (lc $1, uc($2 // $3 // ''), $4);
  my $marked = length $mark ? 1 : 0;
  my $has_z  = $mark =~ /Z/ ? 1 : 0;
  my $has_m  = $mark =~ /M/ ? 1 : 0;

  DBIO::Exception->throw("WKT nesting too deep")
    if $type eq 'geometrycollection' && ++$depth > $MAX_DEPTH;

  if ($open ne '(') {
    return { type => $type, coords => [], has_z => $has_z, has_m => $has_m, is_empty => 1 };
  }

  my ($coords, $is_empty);
  if ($type eq 'point') {
    my $leaf = _leaf($s);
    _unreadable() unless $leaf =~ /\S/;
    $coords = _parse_point_str($leaf);
  } elsif ($type eq 'linestring') {
    my $leaf = _leaf($s);
    _unreadable() unless $leaf =~ /\S/;
    $coords = _parse_ring($leaf);
  } elsif ($type eq 'multipoint') {
    # Both forms: "1 2,3 4" and "(1 2),(3 4)". A point holds no comma, so
    # the commas separate the points either way. An EMPTY member has no
    # ordinates and keeps its place as [].
    my @points;
    do {
      if (_empty($s)) {
        push @points, [];
      } elsif ($$s =~ /\G\(/gc) {
        push @points, _parse_point_str(_leaf($s));
      } else {
        $$s =~ /\G([^(),]*)/gc;
        my $bare = $1;
        _unreadable() unless $bare =~ /\S/;
        push @points, _parse_point_str($bare);
      }
    } while (_separator($s));
    $coords = \@points;
  } elsif ($type eq 'polygon') {
    $coords = _rings($s);
  } elsif ($type eq 'multilinestring') {
    my @lines;
    do {
      push @lines, _empty($s) ? [] : _parse_ring(_leaf(_open($s)));
    } while (_separator($s));
    $coords = \@lines;
  } elsif ($type eq 'multipolygon') {
    my @polygons;
    do {
      push @polygons, _empty($s) ? [] : _rings(_open($s));
    } while (_separator($s));
    $coords = \@polygons;
  } else {
    my (@members, $z, $m);
    do {
      my $member = _geometry($s, $depth);
      $z ||= $member->{has_z};
      $m ||= $member->{has_m};
      push @members, {
        type => $member->{type}, coords => $member->{coords}, is_empty => $member->{is_empty},
      };
    } while (_separator($s));
    $coords = \@members;
    ($has_z, $has_m) = ($z ? 1 : 0, $m ? 1 : 0) unless $marked;
    $is_empty = (grep { !$_->{is_empty} } @members) ? 0 : 1;
  }

  # No marker: the ordinates say it, three are Z and four are ZM, as PostGIS
  # reads them.
  if (!$marked && $type ne 'geometrycollection') {
    my $n = _first_point_size($coords);
    ($has_z, $has_m) = ($n >= 3 ? 1 : 0, $n >= 4 ? 1 : 0);
  }

  $is_empty //= ($type eq 'point' || $type eq 'linestring' || $type eq 'polygon')
    ? 0
    : ((grep { @$_ } @$coords) ? 0 : 1);

  return { type => $type, coords => $coords, has_z => $has_z, has_m => $has_m, is_empty => $is_empty };
}

# The text up to the closing parenthesis, which is consumed with it. A
# coordinate list holds no parenthesis.
sub _leaf {
  my ($s) = @_;
  $$s =~ /\G([^()]*)\)/gc or _unreadable();
  return $1;
}

# After a member: true at a comma (another member follows), false at the
# closing parenthesis of the list, both consumed.
sub _separator {
  my ($s) = @_;
  $$s =~ /\G\s*(?:(,)|\))/gc or _unreadable();
  return defined $1 ? 1 : 0;
}

# True at EMPTY (consumed); a MULTI* member that is empty keeps its place as [].
sub _empty {
  my ($s) = @_;
  $$s =~ /\G\s*/gc;
  return $$s =~ /\GEMPTY/gci ? 1 : 0;
}

# The opening parenthesis of a member.
sub _open {
  my ($s) = @_;
  $$s =~ /\G\(/gc or _unreadable();
  return $s;
}

# The rings of a polygon, behind its opening parenthesis: "(x y,x y),(...)".
sub _rings {
  my ($s) = @_;
  my @rings;
  do {
    $$s =~ /\G\s*\(/gc or _unreadable();
    push @rings, _parse_ring(_leaf($s));
  } while (_separator($s));
  return \@rings;
}

# Number of ordinates of the first point there is, whatever the nesting; 0
# for a geometry without a point.
sub _first_point_size {
  my ($c) = @_;
  return 0 unless ref $c eq 'ARRAY' && @$c;
  return scalar @$c unless ref $c->[0];
  for (@$c) {
    my $n = _first_point_size($_);
    return $n if $n;
  }
  return 0;
}

# split ' ' skips leading whitespace and splits at whitespace runs, both in
# one pass; a regex trim (\s+\z) would try every start of a run.
sub _parse_point_str {
  my ($str) = @_;
  my @ord = split ' ', $str;
  _unreadable() if @ord < 2 || @ord > 4;
  _unreadable() if grep { !/$NUMBER_RE/ } @ord;
  my @num = map { 0 + $_ } @ord;
  _unreadable() if grep { $_ != $_ || $_ == 9**9**9 || $_ == -9**9**9 } @num;
  \@num;
}

# The points of a list, split at the commas, empty entries kept (an empty one
# is unreadable); each point trims itself.
sub _parse_ring {
  my ($str) = @_;
  return [] unless $str =~ /\S/;
  [ map { _parse_point_str($_) } split /,/, $str, -1 ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser - WKT/EWKT parser for PostGIS geometry values

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 parse

    my $result = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($wkt);

Parses a WKT string and returns a hashref:

    {
      type     => 'point',
      coords   => [...],
      has_z    => 0,
      has_m    => 0,
      is_empty => 0,
    }

Returns C<undef> for unsupported types and for text it cannot read. The
structure is that of L<DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder>
for the same geometry, so a geometry read from the server's text and from
its EWKB is the same hash.

B<The dimension> is read in every form PostGIS prints or reads:

=over

=item * C<ST_AsEWKT> glues C<M> to the type, C<POINTM(1 2 9)>,
C<MULTIPOINTM(...)>, C<GEOMETRYCOLLECTIONM(...)>. It prints B<no marker>
for Z and ZM: C<POINT(1 2 3)> is Z, C<POINT(1 2 3 4)> is ZM, as PostGIS
reads them. Without a marker the number of ordinates of the first point
says it: three are Z, four are ZM. (An empty geometry has no ordinates;
C<ST_AsEWKT> prints C<POINT EMPTY> for a Z one, and that is what is read.)

=item * C<ST_AsText> and this distribution's builder write the marker as a
word of its own, with or without a space before the parenthesis:
C<POINT M (1 2 9)>, C<POINT ZM(1 2 3 4)>, C<POINT Z EMPTY>.

=item * C<POINTZ(1 2 3)> and C<POINTZM(...)>, glued, which PostGIS reads
too.

=back

An explicit marker wins over the ordinates. Type and marker are not case
sensitive. The returned C<type> is the plain type, C<point>, never
C<pointm>.

A C<MULTIPOINT> is read in both of its forms, with and without
parentheses around each point: C<MULTIPOINT((1 2),(3 4))> and
C<MULTIPOINT(1 2,3 4)>.

B<Empty parts> of a C<MULTI*> -- C<MULTIPOINT(EMPTY,(1 2))>,
C<MULTILINESTRING(EMPTY,(0 0,1 1))>,
C<MULTIPOLYGON(EMPTY,((0 0,1 0,1 1,0 0)))> -- stay where they are as an
empty list: C<[[],[1,2]]>. C<is_empty> of the whole is true if all its
parts are.

B<C<GEOMETRYCOLLECTION>>: C<coords> is the list of its members, each a
hashref C<< { type, coords, is_empty } >> with the plain, lower-case type
of the member and the C<coords> it would have on its own (for a
collection in a collection, again such a list). The members may be empty
(C<POINT EMPTY>) and may carry their own marker. The collection's
C<has_z> and C<has_m> are its own marker or, without one, those of its
members. C<undef> if one member is of a type that is not read.

B<Ordinates> are numbers as WKT writes them: an optional minus sign,
digits with an optional fraction (C<3.>, C<-.5>) and an optional exponent
(C<1e5>, C<1E-3>). A point has two to four of them; text with another
count or with a token that is no number is text the parser cannot read,
and the result is C<undef>. A number must be finite: one that is too large
for a double (C<1e9999>) is no number the parser reads, and the result is
C<undef>.

B<Nesting> of collections is limited to 32 levels; deeper input throws a
L<DBIO::Exception> (C<WKT nesting too deep>). The outermost
C<GEOMETRYCOLLECTION> is level 1. The text is read once, from start to end,
so the time it takes is in proportion to its length.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
