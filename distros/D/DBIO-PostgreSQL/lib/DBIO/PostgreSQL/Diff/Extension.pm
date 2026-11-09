package DBIO::PostgreSQL::Diff::Extension;
# ABSTRACT: Diff operations for PostgreSQL extensions

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_literal create_schema_if_missing);

__PACKAGE__->mk_diff_accessors(qw(
  extension_name extension_info old_version new_version old_schema new_schema
));









# The $names by name, except that each comes after the names $after->{$name}
# lists. A listed name that is not among $names is passed over. PostgreSQL
# allows no cycle between extensions; one in a model is cut where it closes.
sub _in_order {
  my ($names, $after) = @_;
  my %pending = map { $_ => 1 } @$names;
  my @ordered;
  _place($_, $after, \%pending, \@ordered) for sort @$names;
  return @ordered;
}

sub _place {
  my ($name, $after, $pending, $ordered) = @_;
  return unless delete $pending->{$name};
  _place($_, $after, $pending, $ordered) for sort @{ $after->{$name} // [] };
  push @$ordered, $name;
}

sub _refuse_not_relocatable {
  my ($name, $have, $declared) = @_;
  my $ext = quote_ident($name);
  die join "\n",
    "refusing to diff: extension $name is installed in schema $have and pg_extensions declares schema $declared, but it is not relocatable",
    '',
    "PostgreSQL moves an extension with ALTER EXTENSION ... SET SCHEMA only if its",
    "control file says relocatable; the control file of $name does not. No statement was generated.",
    '',
    "Declare the schema it is in ($have) or none, or drop and create the extension",
    "yourself in the schema you want (DROP EXTENSION $ext CASCADE takes every",
    "object that uses it, the data of its columns included), and diff again.",
    '';
}

sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  # Created or updated after what it requires.
  my %requires = map { $_ => $target->{$_}{requires} } keys %$target;

  for my $name (_in_order([ keys %$target ], \%requires)) {
    if (!exists $source->{$name}) {
      push @ops, $class->new(
        action         => 'create',
        extension_name => $name,
        extension_info => $target->{$name},
      );
      next;
    }
    # Version changes
    my $src_ver = $source->{$name}{version} // '';
    my $tgt_ver = $target->{$name}{version} // '';
    if ($src_ver ne $tgt_ver) {
      push @ops, $class->new(
        action         => 'update',
        extension_name => $name,
        extension_info => $target->{$name},
        old_version    => $src_ver,
        new_version    => $tgt_ver,
      );
    }
    # Schema changes: only a schema the target declares.
    my $declared = $target->{$name}{declared_schema};
    my $have     = $source->{$name}{schema_name};
    if (defined $declared && defined $have && $declared ne $have) {
      _refuse_not_relocatable($name, $have, $declared)
        unless $source->{$name}{relocatable};
      push @ops, $class->new(
        action         => 'move',
        extension_name => $name,
        extension_info => $target->{$name},
        old_schema     => $have,
        new_schema     => $declared,
      );
    }
  }

  # Dropped after what requires it.
  my %required_by;
  for my $name (keys %$source) {
    push @{ $required_by{$_} }, $name for @{ $source->{$name}{requires} // [] };
  }
  my @gone = grep { !exists $target->{$_} } keys %$source;

  for my $name (_in_order(\@gone, \%required_by)) {
    push @ops, $class->new(
      action         => 'drop',
      extension_name => $name,
      extension_info => $source->{$name},
    );
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $extension = quote_ident($self->extension_name);
  if ($self->action eq 'create') {
    my $info   = $self->extension_info // {};
    my $schema = $info->{declared_schema} // $info->{install_schema};
    return sprintf("%s;\nCREATE EXTENSION IF NOT EXISTS %s WITH SCHEMA %s;",
      create_schema_if_missing($schema), $extension, quote_ident($schema))
      if defined $schema && $info->{create_schema};
    return defined $schema
      ? sprintf('CREATE EXTENSION IF NOT EXISTS %s WITH SCHEMA %s;', $extension, quote_ident($schema))
      : sprintf('CREATE EXTENSION IF NOT EXISTS %s;', $extension);
  }
  elsif ($self->action eq 'move') {
    return sprintf 'ALTER EXTENSION %s SET SCHEMA %s;',
      $extension, quote_ident($self->new_schema);
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP EXTENSION %s;', $extension;
  }
  elsif ($self->action eq 'update') {
    return sprintf 'ALTER EXTENSION %s UPDATE TO %s;',
      $extension, quote_literal($self->new_version);
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, 'extension ' . ($self->extension_name // ''));
}


sub summary {
  my ($self) = @_;
  if ($self->action eq 'update') {
    return sprintf '  ~extension: %s (%s -> %s)',
      $self->extension_name, $self->old_version, $self->new_version;
  }
  if ($self->action eq 'move') {
    return sprintf '  ~extension: %s (schema %s -> %s)',
      $self->extension_name, $self->old_schema, $self->new_schema;
  }
  my $info = $self->extension_info // {};
  if ($self->action eq 'create') {
    my $schema = $info->{declared_schema} // $info->{install_schema} // $info->{control_schema};
    my @facts = (
      (defined $info->{version} && length $info->{version} ? ($info->{version}) : ()),
      (defined $schema ? ("schema $schema") : ()),
    );
    return sprintf '  +extension: %s%s', $self->extension_name,
      @facts ? ' (' . join(', ', @facts) . ')' : '';
  }
  # A drop: the extension is installed and the schema does not declare it.
  # DROP EXTENSION (no CASCADE) takes the objects the extension owns; what an
  # extension made at runtime is no member of it, and is named by the
  # operations of its own, where the diff has them in its model.
  my @facts = (
    (defined $info->{version} && length $info->{version} ? ($info->{version}) : ()),
    (defined $info->{schema_name} ? ("schema $info->{schema_name}") : ()),
  );
  return sprintf '  -extension: %s (%snot declared, DROP EXTENSION takes the objects it owns)',
    $self->extension_name, @facts ? join(', ', @facts) . '; ' : '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Extension - Diff operations for PostgreSQL extensions

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents an extension-level diff operation: C<CREATE EXTENSION IF NOT
EXISTS>, C<DROP EXTENSION>, C<ALTER EXTENSION ... UPDATE TO> (version
change) or C<ALTER EXTENSION ... SET SCHEMA> (schema change). Extensions are
compared by name; version differences produce an update operation, and a
declared schema the extension is not in produces a move.

=head1 ATTRIBUTES

=head2 extension_name

The PostgreSQL extension name (e.g. C<pgcrypto>, C<postgis>).

=head2 extension_info

Extension metadata hashref (C<version>, C<schema_name>, C<relocatable>,
C<requires>). In the target model it also carries C<declared_schema> where
L<DBIO::PostgreSQL/pg_extensions> named a schema for the extension, and
C<install_schema> -- the schema a C<create> names: the declared one, else
C<public>; or, for an extension whose control file fixes its schema,
C<control_schema> and no clause: the server installs it there
(L<DBIO::PostgreSQL::Deploy/_mark_extension_schemas>). C<create_schema> is set on a connection that
names its namespace when that schema is not C<public>: a C<create> then creates
the schema first.

=head2 old_version

For an C<update> operation: the version the source has, an empty string where
it carries none. Read by L</summary>. Not set for C<create> and C<drop>.

=head2 new_version

For an C<update> operation: the version the target has, which L</as_sql>
writes into C<ALTER EXTENSION ... UPDATE TO>. Not set for C<create> and
C<drop>.

=head2 old_schema

For a C<move> operation: the schema the source has the extension in. Read by
L</summary>.

=head2 new_schema

For a C<move> operation: the declared schema, which L</as_sql> writes into
C<ALTER EXTENSION ... SET SCHEMA>. A C<create> operation takes its schema
from C<declared_schema> of L</extension_info>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Extension->diff($source, $target);

Compares extension hashrefs. Produces C<create>, C<update> (version changed),
or C<drop> operations.

The operations come in the order the extensions depend on one another, which
each entry states in C<requires>
(L<DBIO::PostgreSQL::Introspect::Extensions/fetch>): an extension is created
or updated after every extension it requires, and dropped before every one of
them. PostgreSQL accepts no other order -- C<CREATE EXTENSION
postgis_topology> without C<postgis> fails with C<required extension
"postgis" is not installed>, C<DROP EXTENSION postgis> ahead of
C<postgis_topology> with C<cannot drop extension postgis because other
objects depend on it>. Extensions with no dependency between them, and those
of a model that carries none, come by name.

B<Schema.> Only a schema the target B<declares> is compared: a target entry
with C<declared_schema> (what L<DBIO::PostgreSQL/pg_extensions> was given
with C<< name => { schema => ... } >>). An extension the source has in another
schema is moved there by C<ALTER EXTENSION ... SET SCHEMA> if the source says
it is relocatable (C<relocatable>). One that is not -- C<postgis>, C<age> --
is refused, here, as the operations are built: C<refusing to diff: ...>, naming
the extension, both schemas and the way out, and no statement for anything
(L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED>). An entry without
C<declared_schema> is never moved, wherever the target model, read from the
temporary database, has it: the list form of C<pg_extensions> names no place.
The move comes after the update of the same extension.

=head2 as_sql

Returns the SQL for this operation. The extension name is an identifier by
the server's rule (L<DBIO::PostgreSQL::Util/quote_ident>) -- C<uuid-ossp> is
no statement without its quotes -- and so is a schema, the version a literal
(L<DBIO::PostgreSQL::Util/quote_literal>). A C<create> writes C<WITH SCHEMA>
for an extension whose C<extension_info> has a C<declared_schema> or, without
one, an C<install_schema>; one with a C<control_schema> only is written
without (the server installs it in that schema). With C<create_schema> in
C<extension_info> -- the deploy of a connection that names its namespace
cannot see the schema of the extension -- the statement is behind a
creation of that schema that looks it up in C<pg_namespace> first
(L<DBIO::PostgreSQL::Util/create_schema_if_missing>). For an
C<action> this class does not know it dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>).

=head2 summary

Returns a one-line description:

  +extension: pgcrypto (1.3)                  a create: the version, and the schema where one is declared
  ~extension: postgis (3.3 -> 3.4)            an update
  ~extension: vector (schema public -> ext)   a move
  -extension: citext (1.6, schema public; not declared, DROP EXTENSION takes the objects it owns)

A drop is an installed extension the schema does not declare (ADR 0066,
decision 4): only an unrestricted deploy drops one
(L<DBIO::PostgreSQL::Deploy/diff>), and a restricted deploy keeps it and does
not name it. The summary says what C<DROP EXTENSION> does -- it takes the
objects the extension owns -- and nothing more: what an extension made at
runtime (the graph schemas of AGE, the topology schemas of PostGIS Topology) is
no member of it, see L<DBIO::PostgreSQL::Extension/postgis_topology>; where the
diff has those objects in its model they are operations of their own, next to
this one.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
