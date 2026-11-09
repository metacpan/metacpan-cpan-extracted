package DBIO::PostgreSQL::Diff::ForeignKey;
# ABSTRACT: Diff operations for PostgreSQL foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified deferrable_clause);

__PACKAGE__->mk_diff_accessors(qw(
  table_key schema_name table_name constraint_name fk_info
  replaced not_valid existing_table ahead_of_table
));












sub _action {
  my ($action) = @_;
  $action = uc($action // 'NO ACTION');
  $action =~ s/\s+/ /g;
  return $action;
}

sub _match {
  my ($match) = @_;
  return uc($match || 'SIMPLE');
}

# The timing of a key as the model says it: (deferrable, initially_deferred). A
# model that has only the older is_deferrable is read as deferrable.
sub _timing {
  my ($info) = @_;
  return (($info->{deferrable} // $info->{is_deferrable}) ? 1 : 0, $info->{initially_deferred} ? 1 : 0);
}

# The fields of a key that make it another key. Validity is not one: it is the
# same key, validated or not (_invalid).
sub _redefined {
  my ($old, $new) = @_;
  return 1 if join("\0", _timing($old)) ne join("\0", _timing($new));
  for my $field (qw( remote_schema remote_table )) {
    return 1 if ($old->{$field} // '') ne ($new->{$field} // '');
  }
  for my $field (qw( local_columns remote_columns on_delete_columns )) {
    return 1 if join("\0", @{ $old->{$field} // [] }) ne join("\0", @{ $new->{$field} // [] });
  }
  for my $field (qw( on_delete on_update )) {
    return 1 if _action($old->{$field}) ne _action($new->{$field});
  }
  return 1 if _match($old->{match}) ne _match($new->{match});
  return 0;
}

# The key the database holds is NOT VALID and the target's is valid (a model
# that says nothing of it holds a valid key: the target is what the install
# built).
sub _invalid {
  my ($old, $new) = @_;
  return (!($old->{is_valid} // 1) && ($new->{is_valid} // 1)) ? 1 : 0;
}

sub _differs {
  my ($old, $new) = @_;
  return _redefined($old, $new) || _invalid($old, $new);
}

sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  $source        //= {};
  $target        //= {};
  $source_tables //= $source;
  $target_tables //= $target;

  # Every table that had a key is walked, though the target has no entry for
  # it (the introspection files none for a table without a key): an empty one,
  # so that the key the target no longer has is seen.
  #
  # Only tables the target has are looked at. The keys of a table that is
  # dropped go with the table, and a section that names a table its model
  # lacks is no more than that. The exception is a key between two tables
  # that are both dropped (below): DROP TABLE finds a key of the other table
  # on the table it drops.
  my $all_source = $source;
  my %source = map { $_ => $source->{$_} } grep { exists $target_tables->{$_} } keys %$source;
  my %target = ((map { $_ => [] } keys %source),
    map { $_ => $target->{$_} } grep { exists $target_tables->{$_} } keys %$target);
  $source = \%source;

  my $op = sub {
    my ($action, $table_key, $name, $info, %more) = @_;
    my ($schema, $table) = DBIO::PostgreSQL::Introspect->key_names(
      $table_key, table_name => $source_tables->{$table_key}, $target_tables->{$table_key});
    return $class->new(
      action => $action, table_key => $table_key, schema_name => $schema, table_name => $table,
      constraint_name => $name, fk_info => $info, %more);
  };

  my @ops = $class->diff_nested(
    $source, \%target,
    index_by      => 'constraint_name',
    scope         => 'all',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => \&_differs,
    on_new => sub {
      my ($table_key, $name, $info) = @_;
      return $op->('create', $table_key, $name, $info,
        existing_table => (exists $source_tables->{$table_key} ? 1 : 0));
    },
    on_changed => sub {
      my ($table_key, $name, $old, $new) = @_;
      return $op->('validate', $table_key, $name, $new) unless _redefined($old, $new);
      return (
        $op->('drop',   $table_key, $name, $old, replaced => 1),
        $op->('create', $table_key, $name, $new,
          existing_table => (exists $source_tables->{$table_key} ? 1 : 0)),
      );
    },
    on_gone => sub {
      my ($table_key, $name, $info) = @_;
      return $op->('drop', $table_key, $name, $info);
    },
  );

  # The keys that tie tables dropped together in a circle: no order of the
  # drops takes them.
  for my $key (grep { $_->{cyclic} } $class->dropped_together($all_source, $source_tables, $target_tables)) {
    push @ops, $op->('drop', $key->{holder}, $key->{info}{constraint_name}, $key->{info}, ahead_of_table => 1);
  }

  return @ops;
}


sub dropped_together {
  my ($class, $fks, $source_tables, $target_tables) = @_;
  $fks           //= {};
  $source_tables //= {};
  $target_tables //= {};
  my %dropped = map { $_ => 1 } grep { !exists $target_tables->{$_} } keys %$source_tables;

  my @keys;
  for my $holder (sort keys %$fks) {
    next unless $dropped{$holder};
    for my $info (@{ $fks->{$holder} }) {
      next unless defined $info->{remote_schema} && defined $info->{remote_table};   # a key that names no table
      my $referenced = DBIO::PostgreSQL::Introspect->qualified_key($info->{remote_schema}, $info->{remote_table});
      next if $referenced eq $holder || !$dropped{$referenced};
      push @keys, { holder => $holder, referenced => $referenced, info => $info };
    }
  }

  my %to;
  push @{ $to{ $_->{holder} } }, $_->{referenced} for @keys;
  my $reaches = sub {
    my ($from, $goal) = @_;
    my (%seen, @todo) = ();
    @todo = ($from);
    while (defined(my $next = shift @todo)) {
      return 1 if $next eq $goal;
      next if $seen{$next}++;
      push @todo, @{ $to{$next} // [] };
    }
    return 0;
  };
  $_->{cyclic} = $reaches->($_->{referenced}, $_->{holder}) for @keys;

  return @keys;
}


sub split_outside {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  $source        //= {};
  $target        //= {};
  $source_tables //= {};
  $target_tables //= {};

  my $outside = sub {
    my ($info) = @_;
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($info->{remote_schema}, $info->{remote_table});
    return !exists $source_tables->{$key} && !exists $target_tables->{$key};
  };

  my (%source, %target, @kept);
  for my $table_key (sort keys %$source) {
    my @in;
    for my $info (@{ $source->{$table_key} }) {
      my $redefined = grep { $_->{constraint_name} eq $info->{constraint_name}
          && ($_->{remote_schema} // "") . "\0" . $_->{remote_table} ne ($info->{remote_schema} // "") . "\0" . $info->{remote_table} } @{ $target->{$table_key} // [] };
      if ($outside->($info) && !$redefined) {
        # A table the target lacks goes with its keys; nothing is kept there.
        next unless exists $target_tables->{$table_key};
        my ($schema, $table) = DBIO::PostgreSQL::Introspect->key_names(
          $table_key, table_name => $source_tables->{$table_key}, $target_tables->{$table_key});
        push @kept, $class->new(
          action => 'kept', table_key => $table_key, schema_name => $schema, table_name => $table,
          constraint_name => $info->{constraint_name}, fk_info => $info);
      }
      else { push @in, $info }
    }
    $source{$table_key} = \@in;
  }
  # The target's key of the same name is not compared with the one kept. A key
  # only the target has is created, wherever it points.
  my %kept = map { ($_->table_key . "\0" . $_->constraint_name) => 1 } @kept;
  for my $table_key (keys %$target) {
    $target{$table_key} = [ grep { !$kept{ $table_key . "\0" . $_->{constraint_name} } } @{ $target->{$table_key} } ];
  }
  return (\%source, \%target, @kept);
}


sub with_validation {
  my ($class, @ops) = @_;
  my @validate;
  for my $op (@ops) {
    next unless $op->action eq 'create' && $op->existing_table;
    $op->not_valid(1);
    push @validate, $class->new(
      action => 'validate', table_key => $op->table_key, schema_name => $op->schema_name,
      table_name => $op->table_name, constraint_name => $op->constraint_name, fk_info => $op->fk_info);
  }
  return (@ops, @validate);
}


sub as_sql {
  my ($self) = @_;
  my $table = quote_qualified(
    DBIO::PostgreSQL::Introspect->key_names($self->table_key, table_name => $self));
  my $name = quote_ident($self->constraint_name);
  my $action = $self->action;

  if ($action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', $table, $name;
  }
  elsif ($action eq 'validate') {
    return sprintf 'ALTER TABLE %s VALIDATE CONSTRAINT %s;', $table, $name;
  }
  elsif ($action eq 'create') {
    my $info = $self->fk_info;
    my $sql = sprintf 'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s (%s)',
      $table, $name,
      join(', ', map { quote_ident($_) } @{ $info->{local_columns} }),
      quote_qualified($info->{remote_schema}, $info->{remote_table}),
      join(', ', map { quote_ident($_) } @{ $info->{remote_columns} });
    $sql .= ' MATCH ' . _match($info->{match}) unless _match($info->{match}) eq 'SIMPLE';
    for my $event (qw( delete update )) {
      my $word = _action($info->{"on_$event"});
      next if $word eq 'NO ACTION';
      $sql .= sprintf ' ON %s %s', uc $event, $word;
      my @cols = @{ $info->{"on_${event}_columns"} // [] };
      $sql .= ' (' . join(', ', map { quote_ident($_) } @cols) . ')' if @cols;
    }
    $sql .= deferrable_clause(_timing($info));
    $sql .= ' NOT VALID' if $self->not_valid;
    return "$sql;";
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, 'foreign key ' . $self->constraint_name);
}


sub summary {
  my ($self) = @_;
  my $info = $self->fk_info // {};
  my $on = $self->table_key;
  my $to = DBIO::PostgreSQL::Introspect->qualified_key($info->{remote_schema}, $info->{remote_table});
  my $action = $self->action;

  return sprintf '  ~fk: %s (on %s) validate', $self->constraint_name, $on if $action eq 'validate';
  return sprintf '  =fk: %s (on %s -> %s) -- kept (target outside the deploy)', $self->constraint_name, $on, $to
    if $action eq 'kept';
  my $head = sprintf '  %s %s (on %s -> %s)', ($action eq 'create' ? '+fk:' : '-fk:'), $self->constraint_name, $on, $to;
  return $head . ($self->not_valid ? ' NOT VALID' : '') if $action eq 'create';
  return $head . ' -- dropped ahead of its table' if $self->ahead_of_table;
  return $head . ($self->replaced ? ' -- changed, created again' : ' -- not declared by the schema, dropped');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::ForeignKey - Diff operations for PostgreSQL foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a foreign key diff operation: C<ALTER TABLE ... ADD CONSTRAINT ...
FOREIGN KEY>, C<DROP CONSTRAINT>, and with the option L</not_valid> the
C<VALIDATE CONSTRAINT> that follows an C<ADD ... NOT VALID>.

The install writes a foreign key for a C<belongs_to> of a class with
C<pg_fk_constraints_from_rels>, with the C<ON DELETE> and C<ON UPDATE> it
declares (L<DBIO::PostgreSQL::DDL>). The target model of a deploy is read from
a database that install built, so it holds that constraint under the name the
install gave it (C<< <table>_<column>_fkey >>), and the diff takes the name
from there: install and diff write one constraint.

=head2 DEFERRABLE

The model keys C<deferrable> and C<initially_deferred> are read
from C<pg_constraint.condeferrable> and C<condeferred>, written by the install
for the attributes of the same names of a C<belongs_to>, written by this class
(C<DEFERRABLE INITIALLY IMMEDIATE>, C<DEFERRABLE INITIALLY DEFERRED>, nothing
for a key that is not deferrable) and compared: a key that changes either is
dropped and created again. A model that has only the older C<is_deferrable>
is read as C<deferrable>.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key of the table that holds the key. It is where the model
files the table, and what L</summary> prints; it is not SQL.

=head2 schema_name

The schema of that table.

=head2 table_name

The name of that table. L</as_sql> writes the table from C<schema_name> and
C<table_name>, each quoted for itself; the key cannot be taken apart again.

=head2 constraint_name

The name of the constraint.

=head2 fk_info

The entry of L<DBIO::PostgreSQL::Introspect::ForeignKeys>: C<local_columns>,
C<remote_schema>, C<remote_table>, C<remote_columns>, C<on_delete>,
C<on_update>, C<match>, C<on_delete_columns>, C<deferrable>,
C<initially_deferred>, C<is_valid>.

=head2 replaced

True for the C<drop> that is the first half of a drop and create of a key
whose definition changed. It stays ahead of its C<create>; any other C<drop>
is a removal and runs with the others, at the end of the diff.

=head2 not_valid

True for a C<create> that is written C<NOT VALID>. See L</with_validation>.

=head2 ahead_of_table

True for the C<drop> of a key between tables that are dropped in the same diff
and point at each other in a circle: no order of the C<DROP TABLE>s takes them.

=head2 existing_table

True for a C<create> on a table the database has. The key of a table the diff
creates is created on an empty table.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::ForeignKey->diff(
        $source_fks, $target_fks, $source_tables, $target_tables,
    );

C<$source_fks> and C<$target_fks> are the C<foreign_keys> sections of the two
models, C<$source_tables> and C<$target_tables> their C<tables> sections.

Keys are matched by constraint name. A key both have is compared in the form
the introspection gives it: its columns, the table and schema it references,
C<on_delete> and C<on_update> (the server's default C<NO ACTION> and no word at
all are one), C<match> (C<SIMPLE>, the default, or C<FULL>) and
C<on_delete_columns> (the list of C<ON DELETE SET NULL (columns)>). A key that
differs is dropped and created again, the drop marked L</replaced>.
C<deferrable> and C<initially_deferred> are compared too (L</DEFERRABLE>).

A key both have that is the same key but C<NOT VALID> in the database
(C<is_valid> false: C<pg_constraint.convalidated>) while the target's is valid
(a model without the field holds a valid key) gets one C<ALTER TABLE ...
VALIDATE CONSTRAINT>, no drop and no create. If the rows break it the upgrade
ends at that statement, naming the key; the statement runs in a transaction
of its own (L</with_validation>). The option L</with_validation> adds
nothing to it. A key that is not valid in the target too, or valid in the
database, is no change.

The install cannot declare C<MATCH FULL> or a column list: C<belongs_to> has no
attribute for them. A key made so by C<pg_extra_ddl> is read back from the
database the install built and L</as_sql> writes both in the create.

A key only the target has is created, also on a table the diff creates. A key
only the database has is dropped: the target is what the schema declares, and
a key it does not declare is not kept. The summary says so
(L</summary>). The key of a table that is dropped goes with the table and gets
no statement, nor does a key whose table the target lacks, with one exception:
a key between two tables that are both dropped and lie in a circle of such keys
is dropped ahead of them (C<ahead_of_table>), since the server does not drop a
table while a key of another table points at it, and tables that point at each
other have no order (L</dropped_together>). A key of a table that stays into a
table that is dropped is dropped.

The caller does not call this for a target model without a C<foreign_keys>
section (L<DBIO::PostgreSQL::Diff>): a model built by hand that says nothing
of foreign keys declares none.

=head2 dropped_together

    my @keys = DBIO::PostgreSQL::Diff::ForeignKey->dropped_together(
        $source_fks, $source_tables, $target_tables);

The keys of the database that run between two tables the diff drops (the table
is in C<$source_tables> and not in C<$target_tables>), not a table to itself.
Each is a hashref with C<holder> and C<referenced> (table keys), C<info> (the
entry of the section) and C<cyclic>, true where the referenced table can reach
the holder again by such keys. The server does not drop a table while a key of
another table points at it, so L<DBIO::PostgreSQL::Diff::Table> drops the
holder ahead of the table it references; a key in a circle has no such order
and is dropped by this class ahead of the tables (C<ahead_of_table>).

=head2 split_outside

    my ($source, $target, @kept) = DBIO::PostgreSQL::Diff::ForeignKey->split_outside(
        $source_fks, $target_fks, $source_tables, $target_tables,
    );

A key the database has whose referenced table is in neither model is not the
deploy's: the table is outside it (another schema, one C<pg_schemas> does not
name), and the install of the target, built in a database that lacks that
table, cannot declare the key. Returns both sections without such keys (the
target's key of the same name is not compared with it), and for each one an
operation with the action C<kept>. It is no change: it has no
statement and does not belong in C<operations>, the diff lists it in its
C<summary> (C<=fk: NAME (on TABLE -E<gt> REFERENCED) -- kept (target outside
the deploy)>) so that it is seen. A table that only one model has is inside the
deploy (it is created or dropped), so a key into it is compared and dropped as
any other.

A key whose name the target declares too, on the same table but onto another
table, is not kept: the target redefines it, and the diff drops the database's
and creates the target's (a replacement, not a key left standing).

=head2 with_validation

    my @ops = DBIO::PostgreSQL::Diff::ForeignKey->with_validation(@ops);

The option C<foreign_keys_not_valid> of L<DBIO::PostgreSQL::Diff> and
L<DBIO::PostgreSQL::Deploy>. Marks every C<create> on a table the database has
L</not_valid>, so that C<ADD CONSTRAINT> does not read the rows that are
there, and returns the operations with one C<VALIDATE CONSTRAINT> added for
each, behind all of them. Without the option the key is an ordinary
C<ADD CONSTRAINT>.

C<apply> runs the statements of a diff in one transaction, except each
C<VALIDATE CONSTRAINT>: the storage reports it as not transactional
(L<DBIO::PostgreSQL::Storage/_ddl_statement_is_transactional>), so it runs
after the COMMIT of the C<ADD CONSTRAINT> in a transaction of its own. The
lock of the add is released before the rows are read, and rows that break the
key end C<apply> with the error while the key stays C<NOT VALID>. The key is
not left C<NOT VALID> for good: the next diff reads C<convalidated> and adds
the C<VALIDATE CONSTRAINT> again, which fails on rows that break the key until
they are cleaned up.

=head2 as_sql

The C<ALTER TABLE> statement. The wording of C<ADD CONSTRAINT> is the
install's: C<FOREIGN KEY (columns) REFERENCES table (columns)>, then C<MATCH
FULL> when the key is, then C<ON DELETE> and C<ON UPDATE> unless the action is
C<NO ACTION>, which is what no clause means; C<ON DELETE SET NULL> and C<SET
DEFAULT> carry their column list (PostgreSQL 15) when the key has one; a
deferrable key then says C<DEFERRABLE INITIALLY IMMEDIATE> or C<DEFERRABLE
INITIALLY DEFERRED>. C<NOT VALID> closes it when L</not_valid> is set. Constraint,
tables and columns are identifiers by the server's rule
(L<DBIO::PostgreSQL::Util/quote_ident>).

For an C<action> this class does not know it dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>).

=head2 summary

C<+fk: NAME (on TABLE -E<gt> REFERENCED)> for a key to create, C<NOT VALID>
behind it when it is written so; C<~fk: NAME (on TABLE) validate> for the
C<VALIDATE CONSTRAINT>.

A key that is dropped says why. One the schema does not declare, which the
diff drops because the target does not have it, is marked C<-- not declared by
the schema, dropped>, so that it does not pass unseen; the drop of a key that
is created again is marked as that.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED>

=item * L<DBIO::PostgreSQL::Introspect::ForeignKeys> - where the entries come from

=item * L<DBIO::PostgreSQL::DDL> - the install, which writes the same constraint

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
