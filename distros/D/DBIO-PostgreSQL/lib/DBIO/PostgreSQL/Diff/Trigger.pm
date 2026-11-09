package DBIO::PostgreSQL::Diff::Trigger;
# ABSTRACT: Diff operations for PostgreSQL triggers

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Diff::View ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified);

__PACKAGE__->mk_diff_accessors(qw(
  table_key schema_name table_name trigger_name trigger_info replaced
));









# The schema_name / table_name pair of an operation, from the entry filed
# under the table key.
sub _table_names {
  my ($table_key, @entries) = @_;
  my ($table_name, $schema_name) = reverse
    DBIO::PostgreSQL::Introspect->key_names($table_key, table_name => @entries);
  return (schema_name => $schema_name, table_name => $table_name);
}

sub _refuse_without_definition {
  my ($table_key, $name, $in_database) = @_;
  DBIO::PostgreSQL::Diff::NoStatement->refuse_without_definition(
    kind           => 'trigger',
    name           => "$name on $table_key",
    in_database    => $in_database,
    from           => 'pg_get_triggerdef',
    null_when_gone => 1,
  );
}

sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $source_cols, $target_cols) = @_;
  my @ops;

  # The views that are dropped and created again have lost their triggers by
  # the time these operations run.
  my $rebuilt = DBIO::PostgreSQL::Diff::View->rebuilt(
    $source_tables, $target_tables, $source_cols, $target_cols);

  for my $table_key (sort keys %$target) {
    my $src_trgs = $rebuilt->{$table_key} ? {} : $source->{$table_key} // {};
    my $tgt_trgs = $target->{$table_key};

    for my $name (sort keys %$tgt_trgs) {
      # The trigger of a rebuilt view is created, and is in the database.
      my $in_database = exists(($source->{$table_key} // {})->{$name});
      my $tgt_def = $tgt_trgs->{$name}{definition} // '';

      if (!exists $src_trgs->{$name}) {
        _refuse_without_definition($table_key, $name, $in_database) unless $tgt_def =~ /\S/;
        push @ops, $class->new(
          action       => 'create',
          table_key    => $table_key,
          _table_names($table_key, $tgt_trgs->{$name}),
          trigger_name => $name,
          trigger_info => $tgt_trgs->{$name},
        );
        next;
      }
      # Changed: compare definitions
      my $src_def = $src_trgs->{$name}{definition} // '';
      if ($src_def ne $tgt_def) {
        _refuse_without_definition($table_key, $name, $in_database) unless $tgt_def =~ /\S/;
        push @ops, $class->new(
          action       => 'drop',
          table_key    => $table_key,
          _table_names($table_key, $src_trgs->{$name}),
          trigger_name => $name,
          trigger_info => $src_trgs->{$name},
          replaced     => 1,
        );
        push @ops, $class->new(
          action       => 'create',
          table_key    => $table_key,
          _table_names($table_key, $tgt_trgs->{$name}),
          trigger_name => $name,
          trigger_info => $tgt_trgs->{$name},
        );
      }
    }
  }

  for my $table_key (sort keys %$source) {
    next if $rebuilt->{$table_key};
    my $src_trgs = $source->{$table_key};
    my $tgt_trgs = $target->{$table_key} // {};

    for my $name (sort keys %$src_trgs) {
      next if exists $tgt_trgs->{$name};
      push @ops, $class->new(
        action       => 'drop',
        table_key    => $table_key,
        _table_names($table_key, $src_trgs->{$name}),
        trigger_name => $name,
        trigger_info => $src_trgs->{$name},
      );
    }
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $table = quote_qualified(
    DBIO::PostgreSQL::Introspect->key_names($self->table_key, table_name => $self));
  my $action = $self->action // '';
  my $object = sprintf 'trigger %s on %s', $self->trigger_name // '', $self->table_key // '';

  if ($action eq 'create') {
    my $def = ($self->trigger_info // {})->{definition};
    DBIO::PostgreSQL::Diff::NoStatement->throw(
      $self, $object, 'its trigger_info has no definition',
    ) unless defined $def && $def =~ /\S/;
    return "$def;";
  }
  elsif ($action eq 'drop') {
    return sprintf 'DROP TRIGGER %s ON %s;', quote_ident($self->trigger_name), $table;
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object);
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %strigger: %s on %s', $prefix, $self->trigger_name, $self->table_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Trigger - Diff operations for PostgreSQL triggers

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a trigger-level diff operation: C<CREATE TRIGGER> or C<DROP
TRIGGER>. When a trigger definition changes, it produces a C<DROP> followed by
a C<CREATE>. Triggers are compared using the full C<pg_get_triggerdef> output.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key identifying which table the trigger belongs to. It is
where the model files the table, and what L</summary> prints; it is not SQL.

=head2 schema_name

The schema of that table.

=head2 table_name

The name of that table. L</as_sql> writes the table from C<schema_name> and
C<table_name>, each quoted for itself -- the key cannot be taken apart again,
a schema or a table may have a dot in its name. L</diff> takes both from the
trigger entry. An operation built by hand without them falls back to the key
(L<DBIO::PostgreSQL::Introspect/key_names>).

=head2 trigger_name

The trigger name.

=head2 trigger_info

Trigger metadata hashref (C<definition>, C<timing>, C<event>, etc.).

=head2 replaced

True on the C<drop> of a changed trigger: the trigger is not removed, the
C<create> that follows puts it back with its new definition. It tells
L<DBIO::PostgreSQL::Diff> to leave the two together instead of moving the
drop to the removals (L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Trigger->diff(
      $source, $target, $source_tables, $target_tables);

Compares trigger sets per table. Definition changes produce a drop-then-create
pair.

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::PostgreSQL::Diff> via its
aux-section wiring). They tell which views this diff drops and creates again
(L<DBIO::PostgreSQL::Diff::View/rebuilt>). C<DROP VIEW> takes the triggers of
the view with it, so for such a view every trigger the target has is created,
changed or not, and none is dropped. The C<columns> sections of the two models, when given after them, add the views
that are rebuilt for the type of a column they read. Without the two arguments no
view is taken to be rebuilt.

A trigger to create -- a new one, a changed one, one of a rebuilt view --
that the target model has no C<definition> for is B<refused>, with C<refusing
to diff: ...> and no statement (L<DBIO::PostgreSQL::Diff::NoStatement>): the
definition is all the diff writes a trigger from, and all it compares one by.
For a changed trigger the C<DROP> would be all that is left of the pair.
C<pg_get_triggerdef> gives none for a trigger another session dropped while
the model was read. A trigger only the source lacks the definition of is
dropped and created like any other whose definition differs, and a C<drop>
needs none.

=head2 as_sql

Returns C<CREATE TRIGGER ...;> using the full definition from introspection,
or C<DROP TRIGGER name ON table;>.

A definition from C<pg_get_triggerdef> is the server's own text and is written
as given. In the C<DROP>, trigger and table are identifiers by the server's
rule (L<DBIO::PostgreSQL::Util/quote_ident>).

A C<create> whose C<trigger_info> has no C<definition> has no statement, and
neither has an C<action> this class does not know: C<as_sql> dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>) and returns no comment in its
place. L</diff> builds no such operation; one built by hand can be.

=head2 summary

Returns a one-line description such as C<+trigger: users_modified_at on auth.users>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
