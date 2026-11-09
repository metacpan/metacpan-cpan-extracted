package DBIO::DB2::Diff::Column;
# ABSTRACT: Diff operations for DB2 columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Carp ();
use DBIO::DB2::Type qw(_db2_column_type);
use DBIO::DB2::DDL qw(_db2_quote_ident _db2_quote_table);
use DBIO::Diff::Compare qw(changed_fields column_change_lossy);


__PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;
  my @ops;

  for my $table_name (sort keys %$target_cols) {
    next unless exists $source_tables->{$table_name}
             && exists $target_tables->{$table_name};

    # A view has no columns to ALTER: DBIO::DB2::Diff::View creates and drops
    # it, and its columns follow its definition (karr k45, ADR 0011). kind may
    # be marked on either side; a missing kind is 'table'.
    next if ($target_tables->{$table_name}{kind} // 'table') eq 'view'
         || ($source_tables->{$table_name}{kind} // 'table') eq 'view';

    my %src_by_name = map { $_->{column_name} => $_ } @{ $source_cols->{$table_name} // [] };
    my %tgt_by_name = map { $_->{column_name} => $_ } @{ $target_cols->{$table_name} // [] };

    my @table_ops;

    for my $col_name (sort keys %tgt_by_name) {
      my $tgt = $tgt_by_name{$col_name};

      if (!exists $src_by_name{$col_name}) {
        _check_identity($table_name, $col_name, undef, $tgt);
        push @table_ops, $class->new(
          action      => 'add',
          table_name  => $table_name,
          column_name => $col_name,
          new_info    => $tgt,
        );
        next;
      }

      my $src = $src_by_name{$col_name};

      my $identity_changed = ($src->{is_auto_increment} ? 1 : 0)
                          != ($tgt->{is_auto_increment} ? 1 : 0);

      if ($identity_changed || scalar _changed_catalog_fields($src, $tgt)) {
        _check_identity($table_name, $col_name, $src, $tgt);
        push @table_ops, $class->new(
          action      => 'alter',
          table_name  => $table_name,
          column_name => $col_name,
          old_info    => $src,
          new_info    => $tgt,
        );
      }
    }

    for my $col_name (sort keys %src_by_name) {
      next if exists $tgt_by_name{$col_name};
      push @table_ops, $class->new(
        action      => 'drop',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $src_by_name{$col_name},
      );
    }

    # A table has one identity column (SQL0372N): whatever lets go of its
    # identity goes first, or the SET GENERATED of another column fails.
    push @ops, (grep {  $_->_releases_identity } @table_ops),
               (grep { !$_->_releases_identity } @table_ops);
  }

  return @ops;
}

# The comparison core's changed_column_fields, on the catalog fields: the
# models hold the normalized column for the generator and the catalog's own
# TYPENAME, LENGTH and DEFAULT for this diff (ADR 0013). Same rules as there:
# a field the target leaves undef is not compared.
sub _changed_catalog_fields {
  my ($old, $new) = @_;
  my @changed = changed_fields($old, $new,
    type   => ['catalog_type'],
    scalar => ['not_null', 'catalog_default'],
    dim    => ['catalog_size'],
  );
  # A default the target no longer declares is a change, as core's
  # changed_column_fields has it since karr k367: the live column carries one (a
  # live DEFAULT NULL is none), the target leaves it undef. The pass above skips
  # a field the target leaves undef, so the removal would never be written
  # (conformance case diff-default-removed, karr k57). Placed after not_null,
  # where the scalar pass puts catalog_default.
  if (!defined $new->{catalog_default} && defined $old->{catalog_default}
      && uc($old->{catalog_default}) ne 'NULL'
      && !grep { $_ eq 'catalog_default' } @changed) {
    my ($at) = grep { $changed[$_] eq 'not_null' } 0 .. $#changed;
    splice @changed, defined $at ? $at + 1 : scalar(@changed), 0, 'catalog_default';
  }
  return @changed;
}


my %LOSSLESS_PAIRS = map { ($_ => 1) } (
  'smallint->integer', 'smallint->bigint', 'integer->bigint',
);

sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  my ($old, $new) = ($self->old_info, $self->new_info);
  return column_change_lossy(
    { data_type => $old->{catalog_type}, size => $old->{catalog_size} },
    { data_type => $new->{catalog_type}, size => $new->{catalog_size} },
    \%LOSSLESS_PAIRS,
  ) ? 1 : 0;
}


sub adds_identity {
  my ($self) = @_;
  return ($self->action eq 'add' && $self->new_info->{is_auto_increment}) ? 1 : 0;
}


sub adds_not_null_without_default {
  my ($self) = @_;
  return 0 unless $self->action eq 'add';
  my $info = $self->new_info;
  return 0 if $info->{is_auto_increment} || !$info->{not_null};
  my $default = $info->{catalog_default};
  return (defined $default && uc($default) ne 'NULL') ? 0 : 1;
}


sub sets_not_null {
  my ($self) = @_;
  return ($self->action eq 'alter'
    && !($self->old_info->{not_null} // 0) && ($self->new_info->{not_null} // 0)) ? 1 : 0;
}

sub _releases_identity {
  my ($self) = @_;
  my $old = $self->old_info or return 0;
  return 0 unless $old->{is_auto_increment};
  return 1 if $self->action eq 'drop';
  return $self->new_info->{is_auto_increment} ? 0 : 1;
}

# The identity cases the server refuses (ADR 0012), refused here with table and
# column named instead of SQL0846N / SQL0270N from the middle of an upgrade.
# $old is undef for an added column. Nothing to check when the column is no
# identity afterwards.
sub _check_identity {
  my ($table, $column, $old, $new) = @_;
  return unless $new->{is_auto_increment};

  my $where = "table $table, column $column";
  my $type  = _db2_column_type($new->{catalog_type}, $new->{catalog_size}, $column);

  Carp::croak("Cannot make an identity column ($where): Db2 takes an identity only over "
    . "SMALLINT, INTEGER, BIGINT or a DECIMAL without scale, not $type")
    unless $type =~ /\A(?:SMALLINT|INTEGER|BIGINT)\z/
        || $type =~ /\A(?:DECIMAL|NUMERIC)(?:\(\s*\d+\s*(?:,\s*0\s*)?\))?\z/;

  Carp::croak("Cannot make an identity column ($where): an identity column must be NOT NULL")
    unless $new->{not_null};

  if ($old && $old->{is_auto_increment}
      && $type ne _db2_column_type($old->{catalog_type}, $old->{catalog_size}, $column)) {
    Carp::croak("Cannot change the type of an identity column ($where) to $type: "
      . "Db2 refuses SET DATA TYPE on an identity column (SQL0270N)");
  }
  return;
}


sub as_sql {
  my ($self) = @_;

  my $tbl = _db2_quote_table($self->table_name);
  my $col = _db2_quote_ident($self->column_name);

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $type = _db2_column_type($info->{catalog_type}, $info->{catalog_size}, $self->column_name);
    my $sql  = sprintf 'ALTER TABLE %s ADD COLUMN %s %s', $tbl, $col, $type;
    $sql .= ' NOT NULL' if $info->{not_null};
    if ($info->{is_auto_increment}) {
      # The only form the server takes (ADR 0012); existing rows stay at 0.
      return join "\n",
        "$sql DEFAULT 0;",
        sprintf('ALTER TABLE %s ALTER COLUMN %s DROP DEFAULT;', $tbl, $col),
        sprintf('ALTER TABLE %s ALTER COLUMN %s SET GENERATED ALWAYS AS IDENTITY;', $tbl, $col);
    }
    if (defined $info->{catalog_default}) {
      # As it is -- the catalog's DEFAULT is SQL text already (see DESCRIPTION).
      $sql .= ' DEFAULT ' . $info->{catalog_default};
    }
    return "$sql;";
  }

  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;', $tbl, $col;
  }

  if ($self->action eq 'alter') {
    my $old = $self->old_info;
    my $new = $self->new_info;
    my @stmts;

    # An identity is let go of before anything else, and taken after the
    # NOT NULL and the missing default it needs (ADR 0012).
    push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s DROP IDENTITY;', $tbl, $col
      if $old->{is_auto_increment} && !$new->{is_auto_increment};

    if (_db2_column_type($old->{catalog_type}, $old->{catalog_size})
        ne _db2_column_type($new->{catalog_type}, $new->{catalog_size})) {
      push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET DATA TYPE %s;',
        $tbl, $col, _db2_column_type($new->{catalog_type}, $new->{catalog_size});
    }
    if (($old->{not_null} // 0) != ($new->{not_null} // 0)) {
      push @stmts, $new->{not_null}
        ? sprintf('ALTER TABLE %s ALTER COLUMN %s SET NOT NULL;', $tbl, $col)
        : sprintf('ALTER TABLE %s ALTER COLUMN %s DROP NOT NULL;', $tbl, $col);
    }
    my $old_d = defined $old->{catalog_default} ? $old->{catalog_default} : '';
    my $new_d = defined $new->{catalog_default} && !$new->{is_auto_increment}
      ? $new->{catalog_default} : '';
    if ($old_d ne $new_d) {
      push @stmts, length $new_d
        ? sprintf('ALTER TABLE %s ALTER COLUMN %s SET DEFAULT %s;', $tbl, $col,
                  $new_d)
        : sprintf('ALTER TABLE %s ALTER COLUMN %s DROP DEFAULT;', $tbl, $col);
    }
    push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET GENERATED ALWAYS AS IDENTITY;', $tbl, $col
      if $new->{is_auto_increment} && !$old->{is_auto_increment};
    return join "\n", @stmts;
  }
}


# The types within which SET DATA TYPE to another length is not
# reorg-recommended, by the name _db2_column_type renders -- which is the
# catalog's TYPENAME for all three.
my %LENGTH_CHANGE_WITHOUT_REORG = map { $_ => 1 } qw(VARCHAR VARGRAPHIC VARBINARY);

sub reorg_recommended {
  my ($self) = @_;

  return 1 if $self->action eq 'drop';
  return 0 unless $self->action eq 'alter';

  my $old = $self->old_info;
  my $new = $self->new_info;

  return 1 if ($old->{not_null} // 0) != ($new->{not_null} // 0);

  my $old_type = _db2_column_type($old->{catalog_type}, $old->{catalog_size});
  my $new_type = _db2_column_type($new->{catalog_type}, $new->{catalog_size});
  return 0 if $old_type eq $new_type;

  (my $old_name = $old_type) =~ s/\(.*\)\z//;
  (my $new_name = $new_type) =~ s/\(.*\)\z//;
  return 0 if $old_name eq $new_name && $LENGTH_CHANGE_WITHOUT_REORG{$new_name};

  return 1;
}


sub summary {
  my ($self) = @_;
  my $type = $self->new_info ? " ($self->{new_info}{catalog_type})" : '';
  return sprintf '  %scolumn: %s.%s%s',
    $self->summary_prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Diff::Column - Diff operations for DB2 columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Column-level diff operations for DB2. DB2 has a reasonably complete
C<ALTER TABLE> repertoire:

=over 4

=item * C<ALTER TABLE ... ADD COLUMN>

=item * C<ALTER TABLE ... DROP COLUMN>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET DATA TYPE>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET NOT NULL / DROP NOT NULL>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET DEFAULT / DROP DEFAULT>

=back

C<DROP COLUMN>, C<SET NOT NULL>, C<DROP NOT NULL> and most C<SET DATA TYPE>
leave the table in reorg-pending state; L</reorg_recommended> says which, and
L<DBIO::DB2::Diff> follows the column pass with the C<REORG>
(L<DBIO::DB2::Diff::Reorg>).

Brand-new tables get their columns inline via L<DBIO::DB2::Diff::Table>
-- this module only sees columns of tables that exist in both models.

Both models are read out of the catalog by
L<DBIO::DB2::Introspect::Columns/fetch>, which gives each column the normalized
fields for the generator and, for this diff, the internal catalog fields; the
catalog fields are what is compared and rendered here (ADR 0013).
C<catalog_type> is C<TYPENAME>. C<catalog_size> is the catalog's length, which
L<DBIO::DB2::Type> leaves out for the types Db2 declares without one.
C<catalog_default> is the SQL text of the default -- C<'new'> with its quotes --
and goes into C<DEFAULT> and C<SET DEFAULT> as it is; quoting it as a literal
would make the quoted text the default, and the next diff would find it
different again. The normalized C<data_type>, C<size> and C<default_value> are
not read.

=head2 Identity columns

C<is_auto_increment> is compared here (L<DBIO::Diff::Compare> does not), and an
identity column can be added to an existing table (ADR 0012). What Db2
12.1.5 takes, as measured:

=over 4

=item * An added identity column is three statements: C<ADD COLUMN ... NOT NULL
DEFAULT 0>, C<ALTER COLUMN ... DROP DEFAULT>, C<ALTER COLUMN ... SET GENERATED
ALWAYS AS IDENTITY>. The clause in C<ADD COLUMN> is refused (SQL0104N), and so
is C<NOT NULL> without a default (SQL0193N). Rows that exist stay at 0.

=item * A changed C<is_auto_increment> between two columns is C<SET GENERATED
ALWAYS AS IDENTITY> (after the C<NOT NULL> and the C<DROP DEFAULT> it needs) or
C<DROP IDENTITY> (before everything else of the column). The operations that let
go of an identity come first within a table: it has one identity column
(SQL0372N).

=back

None of them leaves the table reorg-pending (L</reorg_recommended>). The model
carries no C<START WITH> or C<INCREMENT BY>; the identity written is the
default, 1 and 1, and the counter starts at 1 whatever the column holds.

What the server refuses, the diff refuses with a C<croak> naming table and
column, when the operations are built: an identity over a type other than
C<SMALLINT>, C<INTEGER>, C<BIGINT> or a C<DECIMAL> without scale (SQL0846N),
over a column that is not C<NOT NULL> (SQL0270N), and a change of type of a
column that is an identity before and after (SQL0270N).

C<new>, C<action> and C<summary_prefix> come from L<DBIO::Diff::Op>.

=head1 METHODS

=head2 diff

=head2 lossy

    my $bool = $op->lossy;

True for the C<alter> of a column whose type change can lose or alter stored
values (optional operation method, ADR 0080): L<DBIO::Deploy::Base/apply> runs
such a diff with C<< allow_destructive => 1 >> only. The answer is
L<DBIO::Diff::Compare/column_change_lossy> over the catalog fields the diff
compares, C<catalog_type> as the type and C<catalog_size> as the size (ADR
0013). A change keeps every value when the type stays and the size does not get
smaller (scale equal), or when it is one of the widenings Db2 casts without
loss: C<SMALLINT> to C<INTEGER>, C<SMALLINT> to C<BIGINT>, C<INTEGER> to
C<BIGINT>. Every other type change is lossy. A change of nullability, default or
identity alone is not (C<SET NOT NULL> over a C<NULL> is refused by
L<DBIO::DB2::Deploy/_check_before_apply>), and neither is an added column.

=head2 adds_identity

    my $bool = $op->adds_identity;

True for the C<add> of a column that is an identity: the operation whose
C<ADD COLUMN ... NOT NULL DEFAULT 0> gives every row of the table that exists
the value 0 (see L</Identity columns>). The diff knows no rows;
L<DBIO::DB2::Deploy/apply> asks the server for them before it runs this
operation (ADR 0012).

=head2 adds_not_null_without_default

    my $bool = $op->adds_not_null_without_default;

True for the C<add> of a column that is C<NOT NULL> and has no default (a
C<DEFAULT NULL> is none) and is no identity: Db2 refuses
C<ALTER TABLE ... ADD COLUMN> for it whatever rows the table holds (SQL0193N),
and has nothing to fill the rows with, so no value is made up.
L<DBIO::DB2::Deploy/apply> refuses it before the first statement runs, naming
table and column (the conformance case
C<diff-column-added-not-null-populated>). The identity column is the one
C<NOT NULL> add the diff can write (L</Identity columns>).

=head2 sets_not_null

    my $bool = $op->sets_not_null;

True for the C<alter> of a nullable column into a C<NOT NULL> one. A row that
holds C<NULL> there makes the server refuse C<SET NOT NULL> (SQL0407N) in the
middle of the upgrade; the diff knows no rows, so L<DBIO::DB2::Deploy/apply>
asks the server before the first statement and refuses, naming table and
column (the conformance case C<diff-not-null-over-nulls>).

=head2 as_sql

=head2 reorg_recommended

    my $bool = $op->reorg_recommended;

True when a statement of this operation leaves the table in reorg-pending
state, where Db2 refuses C<INSERT>, C<UPDATE> and C<CREATE INDEX> with
SQL0668N rc 7 until a C<REORG> has run. L<DBIO::DB2::Diff> asks every column
operation and has L<DBIO::DB2::Diff::Reorg> write one C<REORG> per table.

The answers are what Db2 12.1.5 does (measured; the table is in
ADR 0008):

=over 4

=item * C<drop> -- yes.

=item * C<alter> with C<SET NOT NULL> or C<DROP NOT NULL> -- yes.

=item * C<alter> with C<SET DATA TYPE> -- yes, with one exception: a change of
length alone within C<VARCHAR>, C<VARGRAPHIC> or C<VARBINARY>, longer or
shorter. Everything else that was tried asks for one, a longer C<CHAR> and a
wider C<DECIMAL> included, and so does every combination that was not tried:
a C<REORG> too many costs time, one too few breaks the upgrade.

=item * C<add>, and an C<alter> that only sets or drops the default -- no.
Neither do C<SET GENERATED ALWAYS AS IDENTITY> and C<DROP IDENTITY>, nor an
identity column added in its three statements (ADR 0012); the C<NOT NULL> or
type change they come with is asked about as before.

=back

The conditions are the ones L</as_sql> writes its statements on, so the answer
is about the SQL this operation renders and not about the model fields that
differ.

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
