package DBIO::PostgreSQL::Introspect::Parse;
# ABSTRACT: Pure parsers for raw PostgreSQL metadata strings

use strict;
use warnings;



sub include_columns {
  my ($class, $definition) = @_;
  return [] unless defined $definition;
  if ($definition =~ /\bINCLUDE\s*\(([^)]+)\)/i) {
    my $cols = $1;
    return [ map { s/^\s+|\s+$//g; s/^"|"$//g; $_ } split /,/, $cols ];
  }
  return [];
}


sub storage_params {
  my ($class, $reloptions) = @_;
  return {} unless defined $reloptions;
  my $raw = $reloptions;
  $raw =~ s/^\{|\}$//g if !ref $raw;
  my @items = ref $raw ? @$raw : split /,/, $raw;
  my %params;
  for my $item (@items) {
    $item =~ s/^\s+|\s+$//g;
    if ($item =~ /^(.+?)=(.+)$/) {
      $params{$1} = $2;
    }
  }
  return \%params;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Parse - Pure parsers for raw PostgreSQL metadata strings

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Leaf module with pure-data parsers that turn raw C<pg_catalog> strings
(typically produced by C<pg_get_indexdef> and C<reloptions>) into the
canonical Perl structures consumed by L<DBIO::Generate>. None of these
subs talk to the database or hold state; they are class methods that
take scalars / arrayrefs and return arrayrefs / hashrefs.

The parsers are:

=over 4

=item * L</include_columns> -- extracts the C<INCLUDE (col1, col2, ...)>
clause from an index definition

=item * L</storage_params> -- decodes a C<reloptions> array / string of
C<key=value> pairs into a hashref

=back

=head2 include_columns

    my $cols = DBIO::PostgreSQL::Introspect::Parse->include_columns($def);

Returns an ArrayRef of column names listed in the C<INCLUDE (col, col)>
clause of the index definition C<$def>. Returns C<[]> when the clause
is missing or the definition is C<undef>. Column names are stripped of
surrounding whitespace and double quotes.

=head2 storage_params

    my $params = DBIO::PostgreSQL::Introspect::Parse->storage_params($reloptions);

Decodes C<reloptions> (C<pg_class.reloptions>) into a hashref. Accepts
either a string of the form C<{key=value, key=value}> or an ArrayRef
of C<key=value> strings. Returns C<{}> for empty / undef input.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
