package DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder;
# ABSTRACT: EWKB-hex decoder for PostGIS geometry values

use strict;
use warnings;
use Carp qw( croak );
use DBIO::Carp;

my %WKB_TYPES = (
  1 => 'point', 2 => 'linestring', 3 => 'polygon',
  4 => 'multipoint', 5 => 'multilinestring', 6 => 'multipolygon',
  7 => 'geometrycollection',
);

my $SRID_FLAG = 0x20000000;
my $Z_FLAG    = 0x80000000;
my $M_FLAG    = 0x40000000;


sub decode_hex {
  my ($class, $hex) = @_;
  my $bin = pack('H*', $hex);
  my $len = length($bin);
  my $pos = 0;

  croak 'decode_hex: empty input' unless $len > 0;

  my $byte_order = _read_uint8(\$bin, \$pos, $len);
  croak "decode_hex: invalid byte_order" unless $byte_order == 1 || $byte_order == 0;
  my $le = ($byte_order == 1);

  my $type_raw = _read_uint32(\$bin, \$pos, $le, $len);
  my $has_srid = ($type_raw & $SRID_FLAG) ? 1 : 0;
  my $has_z    = ($type_raw & $Z_FLAG)    ? 1 : 0;
  my $has_m    = ($type_raw & $M_FLAG)    ? 1 : 0;
  my $type_id  = $type_raw & 0xFFFF;
  my $type_str = $WKB_TYPES{$type_id} // 'unknown';

  my $srid;
  if ($has_srid) {
    $srid = _read_uint32(\$bin, \$pos, $le, $len);
  }

  my $coords = _read_geometry(\$bin, \$pos, $le, $type_id, $has_z, $has_m, $len);

  return { type => $type_str, srid => $srid, has_z => $has_z, has_m => $has_m, coords => $coords };
}

sub _check_bounds {
  my ($buf, $pos, $need, $len) = @_;
  croak "decode_hex: underrun at pos $$pos (need $need, have " . ($len - $$pos) . ")"
    if $$pos + $need > $len;
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

sub _read_point {
  my ($buf, $pos, $le, $has_z, $has_m, $len) = @_;
  my @c = (_read_double($buf, $pos, $le, $len), _read_double($buf, $pos, $le, $len));
  push @c, _read_double($buf, $pos, $le, $len) if $has_z;
  push @c, _read_double($buf, $pos, $le, $len) if $has_m;
  return \@c;
}

sub _read_geometry {
  my ($buf, $pos, $le, $type_id, $has_z, $has_m, $len) = @_;
  if ($type_id == 1) {
    return _read_point($buf, $pos, $le, $has_z, $has_m, $len);
  }
  my $n = _read_uint32($buf, $pos, $le, $len);
  if ($type_id == 2) {
    return [ map { _read_point($buf, $pos, $le, $has_z, $has_m, $len) } 1..$n ];
  }
  if ($type_id == 3) {
    my @rings;
    for (1..$n) {
      my $m = _read_uint32($buf, $pos, $le, $len);
      push @rings, [ map { _read_point($buf, $pos, $le, $has_z, $has_m, $len) } 1..$m ];
    }
    return \@rings;
  }
  return [ map { _read_subgeom($buf, $pos, $le, $has_z, $has_m, $len) } 1..$n ];
}

sub _read_subgeom {
  my ($buf, $pos, $le, $has_z, $has_m, $len) = @_;
  _read_uint8($buf, $pos, $len);
  my $type_raw = _read_uint32($buf, $pos, $le, $len);
  return _read_geometry($buf, $pos, $le, $type_raw & 0xFFFF, $has_z, $has_m, $len);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder - EWKB-hex decoder for PostGIS geometry values

=head1 VERSION

version 0.900000

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
    }

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
