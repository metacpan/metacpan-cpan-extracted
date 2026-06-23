package DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser;
# ABSTRACT: WKT/EWKT parser for PostGIS geometry values

use strict;
use warnings;


sub parse {
  my ($class, $wkt) = @_;
  return undef unless defined $wkt;
  $wkt =~ s/\A\s+|\s+\z//g;

  if ($wkt !~ /\A([A-Z]+)((?:\s+(?:Z|M|ZM))?)\s*(\(.*\)|EMPTY)\z/si) {
    return undef;
  }
  my ($type_str, $dim_str, $body) = ($1, $2, $3);

  my $type   = lc($type_str);
  my $has_z  = ($dim_str =~ /Z/i && $dim_str !~ /M/i) || $dim_str =~ /ZM/i ? 1 : 0;
  my $has_m  = ($dim_str =~ /M/i)  ? 1 : 0;

  if ($body eq 'EMPTY') {
    return { type => $type, coords => [], has_z => $has_z, has_m => $has_m, is_empty => 1 };
  }

  # Strip only the outermost layer of parentheses
  $body =~ s/\A\((.+)\)\z/$1/;

  my $coords;
  if ($type eq 'point') {
    $coords = _parse_point_str($body, $has_z, $has_m);
  } elsif ($type eq 'linestring') {
    $coords = _parse_ring($body, $has_z, $has_m);
  } elsif ($type eq 'multipoint') {
    $coords = [ map { _parse_point($_, $has_z, $has_m) } _split_by_top_level_commas($body) ];
  } elsif ($type eq 'polygon') {
    $coords = [ map { _parse_ring($_, $has_z, $has_m) } _split_by_top_level_commas($body) ];
  } elsif ($type eq 'multilinestring') {
    $coords = [ map { _parse_ring($_, $has_z, $has_m) } _split_by_top_level_commas($body) ];
  } elsif ($type eq 'multipolygon') {
    $coords = [ map { _parse_one_polygon($_, $has_z, $has_m) } _split_multipolygon($body) ];
  } else {
    return undef;
  }

  return { type => $type, coords => $coords, has_z => $has_z, has_m => $has_m, is_empty => 0 };
}

sub _parse_point_str {
  my ($str, $has_z, $has_m) = @_;
  $str =~ s/\A\s+|\s+\z//g;
  [ map { 0 + $_ } split /\s+/, $str ];
}

# Parse a parenthesized point: "(x y)" or "(x y z)"
sub _parse_point {
  my ($str, $has_z, $has_m) = @_;
  $str =~ s/\A\s*\(|\)\s*\z//g;
  _parse_point_str($str, $has_z, $has_m);
}

sub _parse_ring {
  my ($str, $has_z, $has_m) = @_;
  $str =~ s/\A\s+|\s+\z//g;
  [ map { _parse_point_str($_, $has_z, $has_m) } split /\s*,\s*/, $str ];
}

# Split at top-level commas only (depth tracked via parens)
sub _split_by_top_level_commas {
  my ($str) = @_;
  $str =~ s/\A\s+|\s+\z//g;
  my @parts;
  my ($depth, $start) = (0, 0);
  for my $i (0 .. length($str) - 1) {
    my $ch = substr($str, $i, 1);
    if ($ch eq '(') {
      $start = $i if $depth++ == 0;
    } elsif ($ch eq ')') {
      if (--$depth == 0) {
        push @parts, substr($str, $start + 1, $i - $start - 1);
      }
    }
  }
  return @parts;
}

# Split MULTIPOLYGON body into individual polygon bodies
# e.g. "((0 0,1 0...)),((2 2,3 2...)))" → ["(0 0,1 0...)", "(2 2,3 2...)"]
sub _split_multipolygon {
  my ($str) = @_;
  $str =~ s/\A\s+|\s+\z//g;
  my @polys;
  my ($depth, $start) = (0, 0);
  for my $i (0 .. length($str) - 1) {
    my $ch = substr($str, $i, 1);
    if ($ch eq '(') {
      $start = $i if $depth++ == 0;
    } elsif ($ch eq ')') {
      if (--$depth == 0) {
        push @polys, substr($str, $start, $i - $start + 1);
      }
    }
  }
  return @polys;
}

# Parse a single polygon body (including outer parens) into rings.
# Strip ONE layer of parens — polygon body is "(x y,x y,...,x y)".
sub _parse_one_polygon {
  my ($str, $has_z, $has_m) = @_;
  $str =~ s/\A\s*\((.+)\)\s*\z/$1/s;
  [ map { _parse_ring($_, $has_z, $has_m) } _split_by_top_level_commas($str) ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser - WKT/EWKT parser for PostGIS geometry values

=head1 VERSION

version 0.900000

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

Returns C<undef> for unsupported types.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
