package DBIO::GraphQL::ScalarMap;
# ABSTRACT: Map DBIO column data_types to GraphQL scalars
use strict;
use warnings;

use GraphQL::Type::Scalar qw($Int $String $Float $Boolean);

use Exporter 'import';
our @EXPORT_OK = qw( for_column );

# Resolution order matters:
#   1. Boolean: must come before Int because tinyint(1) is the MySQL idiom
#   2. Float  : decimal/numeric before the int catch-all
#   3. Int    : all integer family types
#   4. String : safe fallback for anything unrecognised
sub for_column {
  my ($source, $col) = @_;
  my $info      = $source->column_info($col);
  my $data_type = $info->{data_type} // '';

  return $Boolean if $data_type =~ /(?:\b(?:bool(?:ean)?)|tinyint\(1\))(?=\s|\z)/i;
  return $Float   if $data_type =~ /\b(?:float|double(?:\s+precision)?|real|money|decimal|numeric)\b/i;
  return $Int     if $data_type =~ /\b(?:int(?:eger)?|bigint|smallint|tinyint|mediumint|serial)\b/i;
  return $String;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::ScalarMap - Map DBIO column data_types to GraphQL scalars

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
