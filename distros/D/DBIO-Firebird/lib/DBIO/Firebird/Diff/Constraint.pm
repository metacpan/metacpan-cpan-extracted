package DBIO::Firebird::Diff::Constraint;
# ABSTRACT: Diff operations for Firebird primary keys, foreign keys and unique constraints

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::Firebird::DDL qw(
  _firebird_quote_ident _firebird_add_foreign_key _firebird_add_unique
);



# new() and the action accessor come from DBIO::Diff::Op.
__PACKAGE__->mk_diff_accessors(qw/table_name kind constraint_name info replaced/);


sub _fk_key {
  my ($fk) = @_;
  return join "\0", join(',', @{ $fk->{from_columns} // [] }), $fk->{to_table} // '',
    join(',', @{ $fk->{to_columns} // [] }),
    map { uc($_ // 'RESTRICT') eq 'NO ACTION' ? 'NO ACTION' : uc($_ // 'RESTRICT') } @{$fk}{qw(on_update on_delete)};
}

sub _unique_key { join ',', @{ $_[0][1] // [] } }

# The primary key is not a model section of its own: it is the is_pk /
# pk_position of the columns. Its columns in key order; its name is the
# primary_key_name of the table.
sub _pk_columns {
  my ($cols) = @_;
  return [ map { $_->{column_name} }
    sort { ($a->{pk_position} // 0) <=> ($b->{pk_position} // 0) }
    grep { $_->{is_pk} } @{ $cols // [] } ];
}

# What a key is over, as the set a foreign key's target is matched against.
sub _column_set { join ',', sort @{ $_[0] // [] } }

sub diff {
  my ($class, $src_uq, $tgt_uq, $src_fk, $tgt_fk, $src_tables, $tgt_tables, $src_cols, $tgt_cols) = @_;
  $_ //= {} for $src_uq, $tgt_uq, $src_fk, $tgt_fk, $src_tables, $tgt_tables, $src_cols, $tgt_cols;

  my (@unique, @fk, %added, %removed, %want_fk);
  my %names = map { $_ => 1 } keys %$tgt_uq, keys %$tgt_fk, keys %$src_uq, keys %$src_fk,
    keys %$tgt_cols, keys %$src_cols;

  my %dropped_key;    # "table\0column set" of a primary key / unique constraint dropped
  my @existing;

  for my $table (sort keys %names) {
    if (exists $tgt_tables->{$table} && !exists $src_tables->{$table}) {
      push @unique, $class->new(
        action => 'create', kind => 'unique', table_name => $table,
        constraint_name => $_->[0], info => $_,
      ) for @{ $tgt_uq->{$table} // [] };
      push @fk, $class->new(
        action => 'create', kind => 'fk', table_name => $table,
        constraint_name => $_->{constraint_name}, info => $_,
      ) for sort { $a->{constraint_name} cmp $b->{constraint_name} } @{ $tgt_fk->{$table} // [] };
      next;
    }
    next unless exists $tgt_tables->{$table} && exists $src_tables->{$table};
    # A view has no constraints of its own.
    next if ($src_tables->{$table}{kind} // '') eq 'view' || ($tgt_tables->{$table}{kind} // '') eq 'view';
    push @existing, $table;

    my ($have_pk, $want_pk) = (_pk_columns($src_cols->{$table}), _pk_columns($tgt_cols->{$table}));
    if (join(',', @$have_pk) ne join(',', @$want_pk)) {
      push @{ $removed{$table} }, [ pk => $have_pk, $src_tables->{$table}{primary_key_name} ] if @$have_pk;
      push @{ $added{$table} },   [ pk => $want_pk ] if @$want_pk;
    }
    for my $pair ([ unique => $src_uq, $tgt_uq, \&_unique_key, sub { $_[0][0] } ],
                  [ fk     => $src_fk, $tgt_fk, \&_fk_key,     sub { $_[0]{constraint_name} } ]) {
      my ($kind, $src, $tgt, $key, $name) = @$pair;
      my %have = map { $key->($_) => $_ } @{ $src->{$table} // [] };
      my %want = map { $key->($_) => $_ } @{ $tgt->{$table} // [] };
      push @{ $added{$table} },   map { [ $kind, $want{$_}, $name->($want{$_}) ] } grep { !exists $have{$_} } sort keys %want;
      push @{ $removed{$table} }, map { [ $kind, $have{$_}, $name->($have{$_}) ] } grep { !exists $want{$_} } sort keys %have;
      %{ $want_fk{$table} } = %want if $kind eq 'fk';
    }
    $dropped_key{ join "\0", $table, _column_set($_->[0] eq 'pk' ? $_->[1] : $_->[1][1]) } = 1
      for grep { $_->[0] ne 'fk' } @{ $removed{$table} // [] };
  }

  # A foreign key that stays but points at a key dropped here: the server
  # refuses to drop the key under it, so it goes too and comes back.
  if (%dropped_key) {
    for my $table (@existing) {
      my %want = %{ $want_fk{$table} // {} };
      my %gone = map { _fk_key($_->[1]) => 1 } grep { $_->[0] eq 'fk' } @{ $removed{$table} // [] };
      for my $fk (@{ $src_fk->{$table} // [] }) {
        my $key = _fk_key($fk);
        next if $gone{$key} || !exists $want{$key};
        next unless $dropped_key{ join "\0", $fk->{to_table} // '', _column_set($fk->{to_columns}) };
        push @{ $removed{$table} }, [ fk => $fk, $fk->{constraint_name} ];
        push @{ $added{$table} },   [ fk => $want{$key}, $want{$key}{constraint_name} ];
      }
    }
  }

  # A drop whose constraint comes back in this diff (the primary key of the
  # table, or a unique constraint / foreign key of the same name) is the first
  # half of a change, not a removal: marked replaced (core ADR 0080).
  my %comes_back;
  for my $table (@existing) {
    for my $item (@{ $added{$table} // [] }) {
      $comes_back{ join "\0", $table, $item->[0], $item->[0] eq 'pk' ? '' : ($item->[2] // '') } = 1;
    }
  }
  my $op = sub {
    my ($action, $table, $item) = @_;
    my ($kind, $info, $name) = @$item;
    my $replaced = $action eq 'drop'
      && $comes_back{ join "\0", $table, $kind, $kind eq 'pk' ? '' : ($name // '') } ? 1 : 0;
    return $class->new(
      action => $action, kind => $kind, table_name => $table,
      constraint_name => $name, info => $info, replaced => $replaced,
    );
  };
  my (@drop_fk, @drop_key, @add_key, @add_fk);
  for my $table (@existing) {
    for my $item (@{ $removed{$table} // [] }) {
      push @{ $item->[0] eq 'fk' ? \@drop_fk : \@drop_key }, $op->(drop => $table, $item);
    }
    for my $item (@{ $added{$table} // [] }) {
      push @{ $item->[0] eq 'fk' ? \@add_fk : \@add_key }, $op->(create => $table, $item);
    }
  }

  return (@unique, @fk, @drop_fk, @drop_key, @add_key, @add_fk);
}

# The statement for one constraint of the model.
sub _add_sql {
  my ($table, $kind, $info) = @_;
  my $table_sql = _firebird_quote_ident($table);
  return sprintf 'ALTER TABLE %s ADD PRIMARY KEY (%s);', $table_sql,
    join(', ', map { _firebird_quote_ident($_) } @$info) if $kind eq 'pk';
  return $kind eq 'unique'
    ? _firebird_add_unique(table_sql => $table_sql, name => $info->[0], columns => $info->[1])
    : _firebird_add_foreign_key(
        table_sql => $table_sql, name => $info->{constraint_name},
        from => $info->{from_columns}, to_table_sql => _firebird_quote_ident($info->{to_table}),
        to => $info->{to_columns}, on_update => $info->{on_update}, on_delete => $info->{on_delete},
      );
}

sub _drop_sql {
  my ($table, $kind, $info, $name) = @_;
  $name = $info->[0] if $kind eq 'unique';
  $name = $info->{constraint_name} if $kind eq 'fk';
  DBIO::Exception->throw(sprintf
    'cannot drop the primary key of table %s: the model holds no name for it (primary_key_name of the table in the tables section)',
    _firebird_quote_ident($table)) unless defined $name && length $name;
  return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', _firebird_quote_ident($table),
    _firebird_quote_ident($name);
}


sub as_sql {
  my ($self) = @_;
  return _drop_sql($self->table_name, $self->kind, $self->info, $self->constraint_name)
    if $self->action eq 'drop';
  return _add_sql($self->table_name, $self->kind, $self->info);
}


sub summary {
  my ($self) = @_;
  if ($self->kind eq 'pk') {
    return sprintf '%s primary key: %s (%s)', $self->summary_prefix,
      $self->table_name, join(', ', @{ $self->info });
  }
  return sprintf '%s %s: %s.%s', $self->summary_prefix,
    ($self->kind eq 'fk' ? 'foreign key' : 'unique constraint'),
    $self->table_name, $self->constraint_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Diff::Constraint - Diff operations for Firebird primary keys, foreign keys and unique constraints

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Primary keys, foreign keys and unique constraints in a diff. The target model
is the temp database L<DBIO::Firebird::Deploy> deploys
L<DBIO::Firebird::DDL/install_ddl> into, so it holds every constraint the
schema declares. Every difference becomes statements:

=over 4

=item * B<A table that is new.> Its constraints are created by

    ALTER TABLE "t" ADD CONSTRAINT "t_a_fk" FOREIGN KEY ("a") REFERENCES "o" ("id");
    ALTER TABLE "t" ADD CONSTRAINT "t_a_b_uq" UNIQUE ("a", "b");

after I<all> the C<CREATE TABLE> statements of the diff, and the unique
constraints before the foreign keys (a key can point at a unique constraint),
so neither the order of the tables nor a cycle between them matters. The
C<CREATE TABLE> of L<DBIO::Firebird::Diff::Table> carries no foreign key.
The statements are written by the helpers C<install_ddl> uses.

=item * B<A table that exists on both sides, with other constraints.> Each
constraint the database has and the schema does not is dropped
(C<ALTER TABLE "t" DROP CONSTRAINT "name">), each the schema has and the
database lacks is added; a constraint that changed -- other columns, other
actions -- is a drop plus an add. The order of a whole diff, set by
L<DBIO::Firebird::Diff>: foreign keys to drop, tables, primary keys and
unique constraints to drop, columns, indexes, primary keys and unique
constraints to add, foreign keys to add. Check constraints are not part of the
model and are never touched.

=back

The B<primary key> is compared too although the model has no
section for it: it is read from C<is_pk> and C<pk_position> of the columns, by
its columns in key order. Its name is the C<primary_key_name> of the table in
the C<tables> section (the server's C<INTEG_E<lt>nE<gt>> unless the table was
created with a named one); a key to add is written without a name,
C<ALTER TABLE "t" ADD PRIMARY KEY (...)>, as C<install_ddl> writes it. A model
without that name cannot drop a primary key: C<as_sql> dies, naming the table.
Firebird has no C<DROP PRIMARY KEY> and refuses a second key, so the old one is
dropped first. A view has no constraints and is skipped.

A key another table's foreign key points at cannot be dropped, so a foreign
key that stays the same but points at a primary key or unique constraint
dropped here is dropped before it and added again after.

A last case: tables dropped together that point at each other in a cycle
(L<DBIO::Firebird::Diff::Table/diff>). The keys among them are dropped by
C<action> C<drop> operations, C<ALTER TABLE ... DROP CONSTRAINT>, before the
tables.

Constraints are compared by what they say, not by name: a foreign key by its
columns, target table, target columns and both actions; a unique constraint by
its columns in order. An absent action and the server's C<RESTRICT> are the same
rule, and a foreign key's C<MATCH> is not compared (Firebird has one, C<FULL>).

=head1 ATTRIBUTES

=head2 replaced

True on a C<drop> whose constraint comes back in the same diff: the primary key
of the table when another one is added, a unique constraint or foreign key of
the same name when it is added again (a changed one, or a foreign key dropped
before the key it points at and added after it). L<DBIO::Diff::Base/classify>
counts such a drop as changing; the drop of a constraint the schema no longer
has is destructive and runs with C<allow_destructive> (core ADR 0080).

=head1 METHODS

=head2 diff

    my @ops = DBIO::Firebird::Diff::Constraint->diff(
      $source_uniques, $target_uniques, $source_fks, $target_fks,
      $source_tables, $target_tables, $source_columns, $target_columns);

The unique constraints of the new tables first, then their foreign keys, then
for the tables that exist on both sides the foreign keys to drop, the primary
keys and unique constraints to drop, those to add, the foreign keys to add.
Each is one operation with C<action> C<create> or C<drop> and C<kind> C<pk>,
C<unique> or C<fk>; L<DBIO::Firebird::Diff> orders them among the other
operations. The columns carry the primary key.

=head2 as_sql

C<ALTER TABLE ... ADD CONSTRAINT> / C<ADD PRIMARY KEY>, or C<ALTER TABLE ...
DROP CONSTRAINT>.

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
