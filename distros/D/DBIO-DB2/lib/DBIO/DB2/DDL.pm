package DBIO::DB2::DDL;
# ABSTRACT: Generate DB2 DDL from DBIO Result classes

use strict;
use warnings;

use DBIO::DB2::Type qw(_db2_column_type);
use DBIO::SQL::Util qw(_quote_ident);

use Exporter 'import';

our @EXPORT_OK = qw(_fk_constraint_clause);



sub install_ddl {
  my ($class, $schema) = @_;

  my @stmts;
  my %seen_table;
  my @view_stmts;
  my %seen_view;

  for my $source_name (_topo_sort_sources($schema)) {
    my $source       = $schema->source($source_name);
    my $result_class = $source->result_class;
    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = _resolve_table_name($source->name);
      next if !defined $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;', _quote_ident($vname), $def;
      next;
    }

    my $table_name   = _resolve_table_name($source->name);

    next unless defined $table_name;
    next if $seen_table{$table_name}++;

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _db2_column_type($info);

      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;

      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};

      if ($info->{is_auto_increment}) {
        # DB2 uses GENERATED ALWAYS AS IDENTITY for auto-increment
        $def .= ' GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)';
      }
      elsif (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        } else {
          $def .= " DEFAULT '$dv'";
        }
      }

      push @col_defs, $def;
    }

    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    # Named inline foreign keys derived from belongs_to relationships. DB2
    # enforces RI, so the install DDL must carry them; the deterministic name
    # (fk_<table>_<from_cols>) makes the constraint round-trip with a stable
    # identity for the name-based diff in DBIO::DB2::Diff::ForeignKey.
    for my $fk (_table_foreign_keys($schema, $source)) {
      push @col_defs, '  ' . _fk_constraint_clause($fk);
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      _quote_ident($table_name), join(",\n", @col_defs);

    # Standalone indexes
    if ($result_class->can('db2_indexes')) {
      my $indexes = $result_class->db2_indexes;
      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        my $columns = join ', ',
          map { _quote_ident($_) } @{ $idx->{columns} // [] };
        my $sql = sprintf 'CREATE %sINDEX %s ON %s (%s)',
          $unique, _quote_ident($idx_name),
          _quote_ident($table_name), $columns;
        push @stmts, "$sql;";
      }
    }
  }

  return join "

", @stmts, @view_stmts;
}

sub _resolve_table_name {
  my ($name) = @_;
  return $name unless ref $name;
  return undef unless ref $name eq 'SCALAR';
  my $v = $$name;
  return undef unless defined $v;
  return $v if $v =~ /\A\w+\z/;
  return undef;
}

# Deterministic constraint name for an FK, derived from the owning table and
# its local columns: fk_<table>_<col1>_<col2>. Stable across the live DB and
# the throwaway compare schema (both built from this same DDL), which is what
# makes the name-based FK diff sound (ADR 0005).
sub _fk_constraint_name {
  my ($table, $from_cols) = @_;
  return join '_', 'fk', $table, @$from_cols;
}

# Single source of truth for the inline foreign-key clause shape (ADR 0005):
#   CONSTRAINT <name> FOREIGN KEY (<from>) REFERENCES <to>(<to_cols>)
#   [ON DELETE <rule>] [ON UPDATE <rule>]
# Returned WITHOUT leading indent and WITHOUT an ALTER TABLE ... ADD prefix, so
# install_ddl (inline, indented), DBIO::DB2::Diff::Table (inline, indented) and
# DBIO::DB2::Diff::ForeignKey (ALTER TABLE ... ADD <clause>) all render the same
# body. NO ACTION rules are suppressed (DB2's implicit default). The name comes
# straight from the model -- callers must NOT regenerate it.
sub _fk_constraint_clause {
  my ($fk) = @_;
  my $sql = sprintf 'CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)',
    _quote_ident($fk->{constraint_name}),
    join(', ', map { _quote_ident($_) } @{ $fk->{from_columns} }),
    _quote_ident($fk->{to_table}),
    join(', ', map { _quote_ident($_) } @{ $fk->{to_columns} });
  $sql .= " ON DELETE $fk->{on_delete}"
    if $fk->{on_delete} && $fk->{on_delete} ne 'NO ACTION';
  $sql .= " ON UPDATE $fk->{on_update}"
    if $fk->{on_update} && $fk->{on_update} ne 'NO ACTION';
  return $sql;
}

# Collect the named foreign keys for one source, derived from its belongs_to
# relationships. Mirrors the column extraction in DBIO::MySQL::DDL: a FK cond
# is { "foreign.<refcol>" => "self.<localcol>" }.
sub _table_foreign_keys {
  my ($schema, $source) = @_;

  my $table_name = _resolve_table_name($source->name);
  my @fks;
  my %seen_name;

  for my $rel ($source->relationships) {
    my $info = $source->relationship_info($rel);
    next unless $info && $info->{attrs}
             && $info->{attrs}{is_foreign_key_constraint};

    my $foreign = $info->{class};
    my $fs = eval { $schema->source($foreign) }
          // eval { $schema->source($foreign =~ s/.*:://r) };
    next unless $fs;

    my $cond = $info->{cond};
    next unless ref $cond eq 'HASH';

    my (@from, @to);
    for my $foreign_col (sort keys %$cond) {
      my $fcol = $foreign_col;
      $fcol =~ s/^foreign\.//;
      my $self_col = $cond->{$foreign_col};
      $self_col =~ s/^self\.//;
      push @to,   $fcol;
      push @from, $self_col;
    }
    next unless @from;

    my $foreign_name = _resolve_table_name($fs->name);
    next unless defined $foreign_name;

    # The deterministic name keys on the local columns, so two relationships
    # over the same column(s) would collide (DB2 rejects a duplicate constraint
    # name, and the name-based diff needs one identity per name). Keep the
    # first; a single FK per column-set is the normal case and is untouched.
    my $name = _fk_constraint_name($table_name, \@from);
    next if $seen_name{$name}++;

    my $attrs = $info->{attrs} || {};
    push @fks, {
      constraint_name => $name,
      from_columns    => \@from,
      to_table        => $foreign_name,
      to_columns      => \@to,
      on_delete       => $attrs->{on_delete},
      on_update       => $attrs->{on_update},
    };
  }

  return @fks;
}

sub _topo_sort_sources {
  my ($schema) = @_;

  my %deps;
  my %by_table;
  my @sources = sort $schema->sources;

  for my $name (@sources) {
    my $s = $schema->source($name);
    my $t = _resolve_table_name($s->name);
    next unless defined $t;
    $by_table{$t} //= $name;
  }

  for my $name (@sources) {
    my $s = $schema->source($name);
    next unless defined _resolve_table_name($s->name);
    $deps{$name} ||= {};
    for my $rel ($s->relationships) {
      my $info = $s->relationship_info($rel);
      next unless $info && $info->{attrs}
               && $info->{attrs}{is_foreign_key_constraint};
      my $foreign = $info->{class};
      my $fs = eval { $schema->source($foreign) }
            // eval { $schema->source($foreign =~ s/.*:://r) };
      next unless $fs;
      my $ft = _resolve_table_name($fs->name);
      next unless defined $ft;
      my $owner = $by_table{$ft};
      next unless $owner;
      next if $owner eq $name;
      $deps{$name}{$owner} = 1;
    }
  }

  my @out;
  my %visited;
  my $visit;
  $visit = sub {
    my ($n) = @_;
    return if $visited{$n}++;
    for my $d (sort keys %{ $deps{$n} || {} }) {
      $visit->($d);
    }
    push @out, $n;
  };
  $visit->($_) for @sources;
  return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::DDL - Generate DB2 DDL from DBIO Result classes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::DB2::DDL> generates a DB2 DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-
compare strategy used by L<DBIO::DB2::Deploy>.

    my $ddl = DBIO::DB2::DDL->install_ddl($schema_class_or_instance);

The output is plain SQL, suitable for executing one statement at a time
against a fresh DB2 database. Emits C<CREATE TABLE> (inline columns,
primary key and named C<FOREIGN KEY> constraints) and C<CREATE INDEX>.

Foreign keys are emitted as B<named> inline constraints
(C<CONSTRAINT fk_E<lt>tableE<gt>_E<lt>colsE<gt> FOREIGN KEY ...>) with a
deterministic name derived from the relationship. DB2 enforces referential
integrity, so the install DDL must carry the FKs; the deterministic name
gives the live database and the throwaway compare schema the same stable
constraint identity, which is what makes the name-based FK diff in
L<DBIO::DB2::Diff::ForeignKey> sound (see ADR 0005). New-table FKs are also
rendered inline by L<DBIO::DB2::Diff::Table> on the diff path.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::DB2::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
