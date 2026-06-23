package DBIO::PostgreSQL::Diff::Schema;
# ABSTRACT: Diff operations for PostgreSQL schemas

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);

__PACKAGE__->mk_diff_accessors(qw(schema_name));





sub diff {
  my ($class, $source, $target) = @_;
  return $class->diff_toplevel(
    $source, $target,
    create => sub { my ($name) = @_; $class->new(action => 'create', schema_name => $name) },
    drop   => sub { my ($name) = @_; $class->new(action => 'drop',   schema_name => $name) },
  );
}


sub as_sql {
  my ($self) = @_;
  if ($self->action eq 'create') {
    return sprintf 'CREATE SCHEMA %s;',
      _quote_ident($self->schema_name);
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP SCHEMA %s CASCADE;',
      _quote_ident($self->schema_name);
  }
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sschema: %s', ($self->action eq 'create' ? '+' : '-'), $self->schema_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Schema - Diff operations for PostgreSQL schemas

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents a single schema (namespace) diff operation: C<CREATE SCHEMA> or
C<DROP SCHEMA CASCADE>. Instances are produced by the L</diff> class method
and consumed by L<DBIO::PostgreSQL::Diff>.

=head1 ATTRIBUTES

=head2 schema_name

The PostgreSQL schema name being created or dropped.

=head2 schema_name

The PostgreSQL schema name being created or dropped.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Schema->diff($source, $target);

Compares two schema hashrefs (as from L<DBIO::PostgreSQL::Introspect::Schemas>)
and returns a list of C<DBIO::PostgreSQL::Diff::Schema> objects representing
schemas to create or drop.

=head2 as_sql

Returns the SQL statement for this operation: C<CREATE SCHEMA name;> or
C<DROP SCHEMA name CASCADE;>.

=head2 summary

Returns a one-line human-readable description such as C<+schema: auth> or
C<-schema: old_ns>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
