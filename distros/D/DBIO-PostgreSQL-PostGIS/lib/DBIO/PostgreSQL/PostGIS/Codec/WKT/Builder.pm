package DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder;
# ABSTRACT: WKT builder for PostGIS geometry structures

use strict;
use warnings;


sub build {
  my ($class, $parsed) = @_;
  my $type = uc($parsed->{type} // '');
  my $dim   = $parsed->{has_z} ? ' Z' : '';
  $dim .= 'M' if $parsed->{has_m};

  return "${type}${dim} EMPTY" if $parsed->{is_empty};

  my $body = $class->_build_coords($parsed->{type}, $parsed->{coords});
  return "${type}${dim}($body)";
}

sub _build_coords {
  my ($class, $type, $coords) = @_;
  $type = lc($type);

  if ($type eq 'point') {
    return join(' ', @$coords);
  }
  if ($type eq 'linestring' || $type eq 'multipoint') {
    return join(',', map { join(' ', @$_) } @$coords);
  }
  if ($type eq 'polygon' || $type eq 'multilinestring') {
    return join(',', map { '(' . join(',', map { join(' ', @$_) } @$_) . ')' } @$coords);
  }
  if ($type eq 'multipolygon') {
    return join(',',
      map {
        '(' . join(',', map { '(' . join(',', map { join(' ', @$_) } @$_) . ')' } @$_) . ')'
      } @$coords
    );
  }
  return '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder - WKT builder for PostGIS geometry structures

=head1 VERSION

version 0.900000

=head1 METHODS

=head2 build

    my $wkt = DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder->build($parsed);

Accepts the hashref returned by L<DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser/parse>
and returns a WKT string.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
