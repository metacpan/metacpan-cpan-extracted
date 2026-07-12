package DBIO::MySQL::Introspect::Util;
# ABSTRACT: Shared helpers for the MySQL/MariaDB introspect submodules

use strict;
use warnings;



sub keep_table {
  my ($class, $tables, $name) = @_;
  return exists $tables->{ $name // '' } ? 1 : 0;
}


sub column_size {
  my ($class, $column_type) = @_;
  return undef unless defined $column_type && length $column_type;
  if ($column_type =~ /^\w+\s*\(\s*(\d+)/) {
    return $1 + 0;  # numericify
  }
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Introspect::Util - Shared helpers for the MySQL/MariaDB introspect submodules

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Leaf module holding the pure-data helpers shared by the per-section
information_schema readers
(L<DBIO::MySQL::Introspect::Columns>, L<DBIO::MySQL::Introspect::Indexes>,
L<DBIO::MySQL::Introspect::ForeignKeys>). None of these subs talk to the
database or hold state; they are class methods that take scalars / hashrefs
and return scalars / hashrefs, so they are trivially unit-testable in
isolation.

The reader submodules all scope their C<information_schema> rows to the
current C<DATABASE()>, then drop any row whose table did not survive
L<DBIO::MySQL::Introspect::Tables> (views are kept, but the C<$tables>
hash is still the single authority for "which objects exist"). That filter
predicate and the C<column_type> size parser were the real duplication when
these readers lived in one file; they live here so the per-section layout
mandated by core ADR 0018 carries no copy-paste.

=head1 METHODS

=head2 keep_table

    next unless DBIO::MySQL::Introspect::Util->keep_table($tables, $name);

True when C<$name> is present in the C<$tables> hashref produced by
L<DBIO::MySQL::Introspect::Tables>. This is the shared C<$tables> filter the
per-table readers apply so they never emit columns / indexes / foreign keys
for an object that L<DBIO::MySQL::Introspect::Tables> did not surface.

=head2 column_size

    my $size = DBIO::MySQL::Introspect::Util->column_size($column_type);

Parse the size component out of a MySQL C<column_type> string. C<size> is the
canonical companion to C<data_type>: L<DBIO::Introspect::Base> relies on it to
size the columns it builds.

    varchar(100)        -> 100
    int(11) unsigned    -> 11
    decimal(10,2)       -> 10
    enum('a','b')       -> undef  (set/enum lengths are not portable)
    text, json, int     -> undef

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
