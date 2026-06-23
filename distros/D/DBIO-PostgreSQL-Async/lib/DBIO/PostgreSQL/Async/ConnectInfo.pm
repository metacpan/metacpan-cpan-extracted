package DBIO::PostgreSQL::Async::ConnectInfo;
# ABSTRACT: PostgreSQL connection string utilities for DBIO async driver

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw( escape_conninfo conninfo_string );


sub escape_conninfo {
  my $val = shift;
  return "''" unless defined $val && length $val;
  return $val unless $val =~ /[\s'\\]/;
  $val =~ s/\\/\\\\/g;
  $val =~ s/'/\\'/g;
  return "'$val'";
}


sub conninfo_string {
  my ($ci) = @_;
  return $ci unless ref $ci;

  return join(' ', map { "$_=" . escape_conninfo($ci->{$_}) }
    grep { defined $ci->{$_} } keys %$ci);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Async::ConnectInfo - PostgreSQL connection string utilities for DBIO async driver

=head1 VERSION

version 0.900000

=func escape_conninfo

  my $escaped = escape_conninfo($value);

Escape a single connection parameter value for use in a libpq conninfo string.
Handles whitespace, single quotes, and backslashes.

=func conninfo_string

  my $str = conninfo_string({ host => 'localhost', port => 5432 });

Convert a hashref of connection parameters into a libpq connection string.
Skips undefined values.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
