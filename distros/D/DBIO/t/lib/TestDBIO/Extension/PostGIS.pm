package TestDBIO::Extension::PostGIS;
# ABSTRACT: PostGIS-like mock extension: annotates geometry columns, judges type changes

use strict;
use warnings;

use base 'DBIO::Extension';

sub extension_interface { 1 }
sub name   { 'postgis' }
sub driver { 'TestDBIO::Extension::Deploy' }

sub annotate {
  my ($class, $model, $ctx) = @_;
  my @triples;
  for my $table (sort keys %{ $model->{tables} || {} }) {
    my $columns = $model->{tables}{$table}{columns} || {};
    for my $column (sort keys %$columns) {
      my $type = $columns->{$column}{type} // '';
      next unless $type =~ /^geometry\((\w+),(\d+)\)$/;
      my $address = [ column => $table, $column ];
      push @triples,
        [ $address, base_type     => 'geometry' ],
        [ $address, geometry_type => $1 ],
        [ $address, srid          => $2 ];
    }
  }
  return \@triples;
}

sub verdict {
  my ($class, $change, $ctx) = @_;
  return undef unless ($change->{kind} // '') eq 'column_type';
  my ($old, $new) = @{$change}{qw(old_info new_info)};
  return undef unless ($old->{base_type} // '') eq 'geometry'
    && ($new->{base_type} // '') eq 'geometry';
  if ($old->{geometry_type} ne $new->{geometry_type}) {
    return { refuse => "column $change->{column_name}: geometry type is not converted" };
  }
  return undef if $old->{srid} == $new->{srid};
  return { using => "ST_Transform($change->{column_name}, $new->{srid})" };
}

1;
