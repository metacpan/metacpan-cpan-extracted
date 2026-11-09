package DBIO::Informix::DDL;
# ABSTRACT: Generate Informix DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Informix::Util qw(_quote_ident);
use DBIO::Informix::ColumnDef qw(column_def_sql);
use DBIO::Informix::Types qw(ddl_type);
use DBIO::Informix::Diff::ForeignKey ();
use DBIO::Diff::Op ();

# What the shared conformance tables ask to be refused rather than built as
# something else: no Informix type or object means what the declaration says.
my $NO_SCHEMAS_REASON = 'Informix has no schemas: owner.name names a user, and a dot '
  . 'would become part of a literal name';

my %REFUSED_TYPE = (
  bit  => 'Informix has no type for a bit string of a fixed width: BOOLEAN is one '
        . 'bit and BYTE is a binary large object, so any mapping changes what the size means',
  enum => 'Informix has no enumerated type, and a VARCHAR with a CHECK would '
        . 'be a different column (its values are not a list the server knows)',
);



sub install_ddl {
  my ($class, $schema) = @_;

  my (@stmts, @unique_idx_stmts, @fk_stmts, @index_stmts, @view_stmts);
  my (%seen_table, %seen_view, %seen_fk, %view_stmt, %view_def);

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $table_name = $source->name;

    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vliteral = ref $table_name eq 'SCALAR';
      my $vname    = $vliteral ? $$table_name : $table_name;
      $source->throw_exception(
        "view '$vname': refused, $NO_SCHEMAS_REASON")
        if !$vliteral && !ref $vname && $vname =~ /\./;
      next if ref $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      $view_stmt{$vname} = sprintf 'CREATE VIEW %s AS %s;',
        ($vliteral ? $vname : _quote_ident($vname)), $def;
      $view_def{$vname} = $def;
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd', emitted
    # unquoted) or an inline subquery source; deref the former, skip the latter.
    my $literal = ref $table_name eq 'SCALAR';
    if ($literal) {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name;

    # Informix has no schemas: owner.table names a user, not a place of the
    # database, and a dotted name would become part of a literal name.
    $source->throw_exception("table '$table_name': refused, $NO_SCHEMAS_REASON")
      if !$literal && $table_name =~ /\./;

    # Several result sources can map to one physical table; emit it once.
    next if $seen_table{$table_name}++;

    my @col_defs;
    my @pk_cols = $source->primary_columns;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      if (my $why = $REFUSED_TYPE{ lc($info->{data_type} // '') }) {
        $source->throw_exception(
          "column '$col_name' on '$table_name': data_type '$info->{data_type}' "
          . "is refused: $why");
      }
      push @col_defs, '  ' . column_def_sql(
        name              => $col_name,
        type              => _informix_column_type($info),
        not_null          => !$info->{is_nullable},     # ADR 0043
        default_value     => $info->{default_value},
        is_auto_increment => $info->{is_auto_increment},
      );
    }

    # Primary key constraint
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { _quote_ident($_) } @pk_cols)
      if @pk_cols;

    # Unique constraints (add_unique_constraint) under the name declared.
    # One over exactly the primary key's columns says nothing more and is not
    # written. Informix holds one index over a column list (-350): a second
    # declaration over the same columns is refused, naming both, never one
    # of them quietly dropped (karr k27).
    my %uniques = $source->unique_constraints;
    my $pk_key  = join "\0", sort @pk_cols;
    my %has_index;    # column list => what declares it, for the message
    $has_index{ join "\0", @pk_cols } = 'the primary key' if @pk_cols;
    my $same_columns = sub {
      my ($key, $what, $cols) = @_;
      my $prev = $has_index{$key} // return;
      $source->throw_exception(
        "table '$table_name': refused, $what and $prev are over the same columns ("
        . join(', ', @$cols) . "); Informix holds only one index there (-350), "
        . "declare the key once");
    };
    for my $uname (sort keys %uniques) {
      next if $uname eq 'primary';
      next if join("\0", sort @{ $uniques{$uname} }) eq $pk_key;
      my $ukey = join "\0", @{ $uniques{$uname} };
      $same_columns->($ukey, "unique constraint '$uname'", $uniques{$uname});
      $has_index{$ukey} = "unique constraint '$uname'";
      push @col_defs, sprintf '  UNIQUE (%s) CONSTRAINT %s',
        join(', ', map { _quote_ident($_) } @{ $uniques{$uname} }), _quote_ident($uname);
    }

    my $qualified = $literal ? $table_name : _quote_ident($table_name);
    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);", $qualified, join(",\n", @col_defs);

    # Foreign keys from the belongs_to relationships (is_foreign_key_constraint).
    # Informix knows ON DELETE CASCADE and nothing else: any other action, an
    # ON UPDATE and DEFERRABLE are refused, never left out. Where the
    # relationship declares no on_delete, the other side decides as
    # DBIO::Relationship::Base describes (a has_many with cascade_delete).
    my %fk_cols;
    for my $rel (sort $source->relationships) {
      my $info = $source->relationship_info($rel);
      next unless $info && $info->{attrs} && $info->{attrs}{is_foreign_key_constraint};

      my $foreign = $info->{class};
      my $foreign_source = eval { $schema->source($foreign) }
        // eval { $schema->source($foreign =~ s/.*:://r) };
      next unless $foreign_source;
      my $cond = $info->{cond};
      next unless ref $cond eq 'HASH';

      my $attrs = $info->{attrs};
      $source->throw_exception(
        "relationship '$rel' on '$table_name': refused, is_deferrable cannot be built, "
        . "Informix has no deferrable constraints")
        if $attrs->{is_deferrable};

      my @pairs;
      for my $foreign_col (sort keys %$cond) {
        (my $fcol = $foreign_col) =~ s/^foreign\.//;
        (my $scol = $cond->{$foreign_col}) =~ s/^self\.//;
        push @pairs, [ $scol, $fcol ];
      }
      # The pairs go in the order of the target key (the first primary key
      # or unique constraint whose columns are these): the server takes a
      # reference only in the key's own order (-297), so a key in another
      # order than the foreign column names is built, not refused (karr k29).
      if (my $key = _key_matching_set($foreign_source, [ map { $_->[1] } @pairs ])) {
        my $i = 0;
        my %pos = map { $_ => $i++ } @$key;
        @pairs = sort { $pos{ $a->[1] } <=> $pos{ $b->[1] } } @pairs;
      }
      my @from = map { $_->[0] } @pairs;
      my @to   = map { $_->[1] } @pairs;

      my $to_name = $foreign_source->name;
      my $to_bare = ref $to_name eq 'SCALAR' ? $$to_name : $to_name;

      # The target of a key is a primary key or a unique constraint; a
      # unique index alone is -297 on the server (karr k27).
      if (my $index = _unique_index_only($foreign_source, \@to)) {
        $source->throw_exception(
          "relationship '$rel' on '$table_name': refused, the foreign key over "
          . join(', ', @from) . " references $to_bare (" . join(', ', @to) . ") which only "
          . "$index covers; Informix wants a primary key or a unique constraint as the target "
          . "(-297). Declare it with add_unique_constraint, as a unique constraint "
          . "instead of a unique index");
      }

      my $on_delete = exists $attrs->{on_delete} ? $attrs->{on_delete}
        : _cascading_has_many($foreign_source, $table_name, \@from, \@to, 'cascade_delete')
          ? 'CASCADE' : undef;
      # Only a declared on_update is asked of the server. cascade_copy is on by
      # default on every has_many, so deriving ON UPDATE CASCADE from it would
      # refuse the ordinary has_many + belongs_to pair; Informix has no ON
      # UPDATE and a derived value is no declaration (karr k25).
      my $on_update = $attrs->{on_update};
      my $where = "relationship '$rel' on '$table_name'";
      $on_delete = _fk_action($source, 'on_delete', $on_delete, $where, 'CASCADE');
      $on_update = _fk_action($source, 'on_update', $on_update, $where);

      # Relationships that declare the same key are one key; the same columns
      # with another action are two keys the server would take as one:
      # refused, never one of them quietly.
      my $by_cols = join "\0", $table_name, @from, '->', $to_bare, @to;
      my $stmt = sprintf 'ALTER TABLE %s ADD CONSTRAINT %s;', $qualified,
        DBIO::Informix::Diff::ForeignKey::fk_clause($table_name, {
          from_columns => \@from, to_table => $to_bare, to_columns => \@to,
          on_delete => $on_delete,
        });
      if (defined(my $prev = $seen_fk{$by_cols})) {
        next if $prev eq $stmt;
        $source->throw_exception(
          "relationship '$rel' on '$table_name': refused, it declares a foreign key over "
          . join(', ', @from) . " that another relationship declares with another "
          . "on_delete action; Informix cannot hold both");
      }
      $seen_fk{$by_cols} = $stmt;
      $fk_cols{ join "\0", @from } = 1;
      push @fk_stmts, $stmt;
    }

    # Unique indexes of a column (is_unique), then the declared indexes
    # (ADR 0061). Informix refuses a second index over the same columns in
    # the same order (-350), and builds one itself for a primary key, a
    # unique constraint and a foreign key: a declaration over the columns of
    # one of the first two is refused (above), a plain index over a foreign
    # key's columns is not written again. A UNIQUE index over a foreign key's columns says more
    # than the key and goes before the key, which then shares it.
    my %declared;
    for my $decl ($source->index_declarations_for('informix', [])) {
      if (defined $decl->{type} && lc $decl->{type} ne 'unique') {
        $source->throw_exception(
          "index '$decl->{name}' on '$table_name': type '$decl->{type}' "
          . "cannot be built on Informix (only a plain or unique index)");
      }
      $source->throw_exception(
        "index '$decl->{name}' on '$table_name': options cannot be built on Informix")
        if defined $decl->{options};
      $declared{ $decl->{name} } = $decl;
    }

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      next unless $info->{is_unique} || $info->{is_single_unique_key};
      next if @pk_cols == 1 && $pk_cols[0] eq $col_name;    # the primary key says it
      $same_columns->($col_name, "the unique column '$col_name'", [$col_name]);
      $has_index{$col_name} = "the unique column '$col_name'";
      push @unique_idx_stmts, sprintf 'CREATE UNIQUE INDEX %s ON %s (%s);',
        _quote_ident("${table_name}_$col_name"), $qualified, _quote_ident($col_name);
    }

    my %fk_index;    # column list of a foreign key => the plain index declared over it
    for my $name (sort keys %declared) {
      my $decl = $declared{$name};
      my $key  = join "\0", @{ $decl->{columns} };
      # a plain index over a foreign key's columns: the key builds one
      if (!$decl->{unique} && $fk_cols{$key} && !defined $has_index{$key}) {
        $fk_index{$key} //= $name;
        $source->throw_exception(
          "table '$table_name': refused, index '$name' and index '$fk_index{$key}' are over the same "
          . "columns (" . join(', ', @{ $decl->{columns} }) . "); Informix holds only one index there "
          . "(-350), declare the key once") if $fk_index{$key} ne $name;
        next;
      }
      $same_columns->($key, "index '$name'", $decl->{columns});
      $has_index{$key} = "index '$name'";
      push @{ $decl->{unique} ? \@unique_idx_stmts : \@index_stmts },
        _create_index($name, $qualified, $decl);
    }
  }

  # A view that reads another is created after it, whatever the alphabet says.
  @view_stmts = map { $view_stmt{$_} } DBIO::Diff::Op::_order_by_dependency(sub {
    my $name = $_[0];
    [ grep { $_ ne $name && $view_def{$name} =~ /(?<![\w\$])\Q$_\E(?![\w\$])/i } keys %view_def ];
  }, keys %view_def);

  return join "

", @stmts, @unique_idx_stmts, @fk_stmts, @index_stmts, @view_stmts;
}

# What covers exactly these columns of $target in a way the server cannot
# reference: a unique index (a declared one, or a column's is_unique), and
# neither the primary key nor a unique constraint. Returns its description,
# or undef when the columns are covered by a key (or by nothing).
sub _unique_index_only {
  my ($target, $cols) = @_;
  my $want = join "\0", sort @$cols;
  return undef if _key_in_order($target, $cols);
  return undef if join("\0", sort $target->primary_columns) eq $want;
  my %uniques = $target->unique_constraints;
  for my $uname (keys %uniques) {
    next if $uname eq 'primary';
    return undef if join("\0", sort @{ $uniques{$uname} }) eq $want;
  }
  for my $decl ($target->index_declarations_for('informix', [])) {
    next unless $decl->{unique};
    return "the unique index '$decl->{name}'" if join("\0", sort @{ $decl->{columns} }) eq $want;
  }
  if (@$cols == 1) {
    my $info = $target->column_info($cols->[0]);
    return "the unique column '$cols->[0]'" if $info && ($info->{is_unique} || $info->{is_single_unique_key});
  }
  return undef;
}

# The primary key and the unique constraints of $target, as [description,
# columns in key order].
sub _target_keys {
  my ($target) = @_;
  my %uniques = $target->unique_constraints;
  return (
    [ 'the primary key', [ $target->primary_columns ] ],
    map { [ "the unique constraint '$_'", $uniques{$_} ] } grep { $_ ne 'primary' } sort keys %uniques,
  );
}

# True when a primary key or unique constraint of $target covers exactly
# these columns in this order (what the server accepts as the target).
sub _key_in_order {
  my ($target, $cols) = @_;
  my $want = join "\0", @$cols;
  return scalar grep { join("\0", @{ $_->[1] }) eq $want } _target_keys($target);
}

# The columns (in key order) of the first primary key or unique constraint
# of $target that covers exactly this set of columns, else undef.
sub _key_matching_set {
  my ($target, $cols) = @_;
  my $set = join "\0", sort @$cols;
  my ($key) = grep { join("\0", sort @{ $_->[1] }) eq $set } _target_keys($target);
  return $key ? $key->[1] : undef;
}

sub _create_index {
  my ($name, $table_sql, $decl) = @_;
  return sprintf 'CREATE %sINDEX %s ON %s (%s);',
    ($decl->{unique} ? 'UNIQUE ' : ''),
    _quote_ident($name), $table_sql,
    join(', ', map { _quote_ident($_) } @{ $decl->{columns} });
}

# The action of one rule as Informix can hold it: ON DELETE CASCADE, or none.
# RESTRICT / NO ACTION are what a key without a clause does. Anything else,
# and any ON UPDATE action, is refused.
sub _fk_action {
  my ($source, $event, $rule, $where, $allowed) = @_;
  return undef unless defined $rule;
  (my $r = uc $rule) =~ s/\A\s+|\s+\z//g;
  $r =~ s/\s+/ /g;
  return undef if $r eq '' || $r eq 'RESTRICT' || $r eq 'NO ACTION';
  return $r if defined $allowed && $r eq $allowed;
  $source->throw_exception(
    "$where: refused, $event '$rule' cannot be built, Informix has "
    . (defined $allowed ? 'only ON DELETE CASCADE' : 'no ON UPDATE action'));
}

# Whether some has_many of $target (the referenced table's source) over the
# column pairs of this key has $attr set: the other side of the belongs_to,
# which is what DBIO::Relationship::Base describes as the autodetection of
# on_delete (cascade_delete) and on_update (cascade_copy).
sub _cascading_has_many {
  my ($target, $table, $from, $to, $attr) = @_;
  my $want = join "\0", sort map { "$from->[$_]\t$to->[$_]" } 0 .. $#$from;
  for my $rel ($target->relationships) {
    my $info = $target->relationship_info($rel) or next;
    next unless $info->{attrs} && $info->{attrs}{$attr};
    next unless ref $info->{cond} eq 'HASH';
    my $other = eval { $target->related_source($rel) } or next;
    my $oname = $other->name;
    $oname = $$oname if ref $oname eq 'SCALAR';
    next unless !ref $oname && $oname eq $table;
    my @pairs;
    for my $k (keys %{ $info->{cond} }) {
      my ($f) = $k =~ /\Aforeign\.(\w+)\z/ or next;
      my ($sc) = ($info->{cond}{$k} // '') =~ /\Aself\.(\w+)\z/ or next;
      push @pairs, "$f\t$sc";    # the child's column, the parent's column
    }
    return 1 if (join "\0", sort @pairs) eq $want;
  }
  return 0;
}

sub _informix_column_type {
  my ($info) = @_;
  return ddl_type($info->{data_type}, $info->{size});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::DDL - Generate Informix DDL from DBIO Result classes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Informix::DDL> generates an Informix DDL script from the L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-compare
strategy used by L<DBIO::Informix::Deploy>.

    my $ddl = DBIO::Informix::DDL->install_ddl($schema_class_or_instance);
    # CREATE TABLE ...; CREATE INDEX ...; ...

Informix holds one index over a column list (-350). Two declarations over the
same columns (two indexes, an index and a unique constraint, two unique
constraints, an index and an C<is_unique> column) are refused with a message
naming both, never one of them left out. Two things say nothing more and are
not written: a unique constraint over exactly the primary key's columns, and a
plain index over a foreign key's columns (the key builds one). A foreign key
whose target columns only a unique index covers is refused as well: Informix
wants a primary key or a unique constraint there (-297), and the message says
to declare it with C<add_unique_constraint>. The
columns of a foreign key are written in the order of the target key (the
first primary key or unique constraint over those columns), as the server
takes a reference only in that order (-297): a key over C<(a, b)> onto a key
over C<(b, a)> is built as C<FOREIGN KEY (b', a') REFERENCES t(b, a)>.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::Informix::DDL->install_ddl($schema);

Returns the full installation DDL as a single string. C<$schema> may be
a connected schema instance or a schema class name.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::Informix> - schema component

=item * L<DBIO::Informix::Deploy> - uses this to generate DDL for deployment

=item * L<DBIO::SQLite::DDL> - sibling implementation

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
