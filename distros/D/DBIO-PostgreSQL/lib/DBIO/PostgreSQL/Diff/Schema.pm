package DBIO::PostgreSQL::Diff::Schema;
# ABSTRACT: Diff operations for PostgreSQL schemas

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::CaseOnly ();
use DBIO::PostgreSQL::Diff::Dependents ();
use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Util qw(quote_ident create_schema_if_missing);

__PACKAGE__->mk_diff_accessors(qw(schema_name if_missing));





# The extensions the diff keeps, by the schema the source has them in.
sub _kept_extensions_by_schema {
  my ($source_extensions, $target_extensions) = @_;
  my %kept;
  for my $name (sort keys %{ $source_extensions // {} }) {
    next unless exists $target_extensions->{$name};
    my $schema = $source_extensions->{$name}{schema_name};
    push @{ $kept{$schema} }, $name if defined $schema;
  }
  return \%kept;
}

sub _refuse_drop_under_extension {
  my ($schema, @extensions) = @_;
  die join "\n",
    sprintf(
      'refusing to diff: schema %s is not in the target and would be dropped, and it holds %s, which the target keeps',
      $schema, join(', ', map { "extension $_" } @extensions),
    ),
    '',
    'An extension depends on the schema it is installed in: the server refuses',
    'DROP SCHEMA ' . quote_ident($schema) . ' while the extension is in it, and CASCADE would drop the',
    'extension too, and with the extension every column, index and',
    'function that uses what it brings -- in tables this diff does not name. No',
    'statement was generated.',
    '',
    'Either keep the schema (declare it with pg_schemas), or take the extension out',
    'of it before the diff -- a relocatable extension moves, any other has to be',
    'dropped and created again:',
    ( map { '  ALTER EXTENSION ' . quote_ident($_) . ' SET SCHEMA ...;' } @extensions ),
    '';
}

sub _refuse_case_only {
  my ($source, $target) = @_;
  DBIO::PostgreSQL::Diff::CaseOnly->refuse(
    'DROP SCHEMA comes after the drop of everything that is in the schema, tables and their rows included.',
    map {
      my ($old, $new) = map { $_->{name} } @$_;
      {
        kind     => 'schema',
        database => $old,
        target   => $new,
        rename   => sprintf('ALTER SCHEMA %s RENAME TO %s;', quote_ident($old), quote_ident($new)),
      }
    } DBIO::PostgreSQL::Diff::CaseOnly->pairs(
      map { [ map { { in => [], name => $_ } } keys %{ $_ // {} } ] } $source, $target,
    ),
  );
}

sub diff {
  my ($class, $source, $target, $source_extensions, $target_extensions, $source_dependents) = @_;

  _refuse_case_only($source, $target);

  my $kept = _kept_extensions_by_schema($source_extensions, $target_extensions);
  for my $name (sort keys %{ $source // {} }) {
    next if exists $target->{$name};
    _refuse_drop_under_extension($name, @{ $kept->{$name} }) if $kept->{$name};
  }

  # What stands in a schema and is not in the model is named, not left to the server.
  DBIO::PostgreSQL::Diff::Dependents->refuse(map { {
    object     => "schema $_",
    dependents => ($source_dependents // {})->{schemas}{$_},
  } } grep { !exists $target->{$_} } sort keys %{ $source // {} });

  return $class->diff_toplevel(
    $source, $target,
    create => sub {
      my ($name) = @_;
      $class->new(action => 'create', schema_name => $name,
        if_missing => ($target->{$name} && $target->{$name}{create_if_missing} ? 1 : 0));
    },
    drop   => sub { my ($name) = @_; $class->new(action => 'drop',   schema_name => $name) },
  );
}


sub as_sql {
  my ($self) = @_;
  if ($self->action eq 'create') {
    return create_schema_if_missing($self->schema_name) . ';'
      if $self->if_missing;
    return sprintf 'CREATE SCHEMA %s;',
      quote_ident($self->schema_name);
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP SCHEMA %s;',
      quote_ident($self->schema_name);
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, 'schema ' . ($self->schema_name // ''));
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

version 0.900004

=head1 DESCRIPTION

Represents a single schema (namespace) diff operation: C<CREATE SCHEMA> or
C<DROP SCHEMA>. Instances are produced by the L</diff> class method
and consumed by L<DBIO::PostgreSQL::Diff>.

=head1 ATTRIBUTES

=head2 schema_name

The PostgreSQL schema name being created or dropped.

=head2 if_missing

True for a create whose entry in the target model carries
C<create_if_missing>, which L<DBIO::PostgreSQL::Deploy> sets on the namespace
of a connection with the connect key C<schema>. The statement then looks the
schema up in C<pg_namespace> and creates it only where it is missing
(L<DBIO::PostgreSQL::Util/create_schema_if_missing>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Schema->diff(
      $source, $target, $source_extensions, $target_extensions,
      $source_outside_dependents);

Compares two schema hashrefs (as from L<DBIO::PostgreSQL::Introspect::Schemas>)
and returns a list of C<DBIO::PostgreSQL::Diff::Schema> objects representing
schemas to create or drop.

The optional C<$source_extensions> / C<$target_extensions> hashrefs are the
C<extensions> sections of the two models (threaded in by
L<DBIO::PostgreSQL::Diff> via its aux-section wiring). With them, a drop is
B<refused> when an extension the diff keeps -- one in both sections -- is
installed in the schema: the extension depends on that schema, so the server
refuses the C<DROP SCHEMA> for it, and the one way to make it pass is C<CASCADE>,
which would drop the extension as well, and with it every column of a type it
brings, in tables the diff was never asked to touch. The diff dies with
C<refusing to diff: ...>, naming the schema and the extension, and generates no
statement. An extension that goes in the same diff is no
obstacle: it is dropped ahead of its schema
(L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>). Without the two arguments
nothing is checked.

A schema to create whose name differs only in upper and lower case from one
to drop -- C<Auth> in the target, C<auth> in the database -- is B<refused> as
well (L<DBIO::PostgreSQL::Diff::CaseOnly>): C<DROP SCHEMA auth> comes after
the drop of every table in it, and its rows. The message names both and the way out,
C<ALTER SCHEMA auth RENAME TO "Auth">. Schemas are the first section the diff
looks at, so this is what is said of such a database -- not that every table
in C<auth> goes and every table in C<Auth> comes.

A deploy that is restricted by L<DBIO::PostgreSQL/pg_schemas> does not get
here with such a pair: its models hold the declared schemas only
(L<DBIO::PostgreSQL::Deploy/_schema_filter>), so an C<auth> beside a declared
C<Auth> is not in them. Its diff creates C<Auth> and everything declared in
it, and leaves C<auth> and its rows where they are -- nothing is lost and
nothing is said.

A schema is dropped without C<CASCADE>. The order of the operations has dropped
what the model holds in it by then: its tables, views, types, functions and the
sequences no column owns (L<DBIO::PostgreSQL::Diff::Sequence/What is not done>),
the extensions that go. What stands in it and the model does not hold -- a
domain, an operator, a collation, an operator class or family, a conversion, a
statistics object, a text search object -- is read into the
C<outside_dependents> section (the fifth argument, the section of the source
model) and B<refused> by name: C<refusing to diff: ...> and no statement
(L<DBIO::PostgreSQL::Diff::Dependents>). Anything else in the schema stops the
C<DROP SCHEMA> itself, and the transaction C<apply> runs in leaves the database
as it was.

=head2 as_sql

Returns the SQL statement for this operation: C<CREATE SCHEMA name;> or
C<DROP SCHEMA name;>. For an C<action> this class does not know it
dies (L<DBIO::PostgreSQL::Diff::NoStatement/throw>).

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
