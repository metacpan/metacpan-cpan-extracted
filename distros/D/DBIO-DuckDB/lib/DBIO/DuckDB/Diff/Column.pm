package DBIO::DuckDB::Diff::Column;
# ABSTRACT: Diff operations for DuckDB columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::DuckDB::DDL::Emit qw(quote_ident quote_table);
use DBIO::DuckDB::DDL::Emit qw(column_def);
use DBIO::Diff::Compare qw(norm_type changed_column_fields column_change_lossy);

__PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);

# a default DuckDB takes in ADD COLUMN: a number, a quoted string, NULL, a boolean
our $CONSTANT_DEFAULT = qr/\A\s*(?:-?\d+(?:\.\d+)?|'(?:[^']|'')*'|NULL|TRUE|FALSE)\s*\z/i;



sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;

  return $class->diff_nested($source_cols, $target_cols,
    index_by      => 'column_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub {
      my ($old, $new) = @_;
      scalar changed_column_fields($old, $new);
    },
    on_new => sub {
      my ($table_name, $col_name, $tgt) = @_;
      $class->new(
        action      => 'add',
        table_name  => $table_name,
        column_name => $col_name,
        new_info    => $tgt,
      );
    },
    on_changed => sub {
      my ($table_name, $col_name, $old, $new) = @_;
      $class->new(
        action      => 'alter',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $old,
        new_info    => $new,
      );
    },
    on_gone => sub {
      my ($table_name, $col_name, $old) = @_;
      $class->new(
        action      => 'drop',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $old,
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;
  my ($early, $late) = $self->_parts;
  return length $late ? "$early\n$late" : $early;
}


sub early_sql { ($_[0]->_parts)[0] }
sub late_sql  { ($_[0]->_parts)[1] }

sub _parts {
  my ($self) = @_;
  my $late = '';

  my $tbl = quote_table($self->table_name);
  my $col = quote_ident($self->column_name);

  if ($self->action eq 'add') {
    my $info    = $self->new_info;
    my $default = $info->{default_value};
    my $type    = $info->{data_type} || 'VARCHAR';

    # DuckDB takes ADD COLUMN with a constant default only: NOT NULL is
    # refused there ("Adding columns with constraints not yet supported") and
    # so is an expression default ("Cannot prepare multiple statements at
    # once"). The rest is done after the column exists.
    my $constant = defined $default && $default =~ $CONSTANT_DEFAULT;
    my @stmts = sprintf 'ALTER TABLE %s ADD COLUMN %s;', $tbl, column_def(
      name    => $self->column_name,
      type    => $type,
      default => ($constant ? $default : undef),
    );
    if (defined $default && !$constant) {
      push @stmts,
        sprintf('ALTER TABLE %s ALTER COLUMN %s SET DEFAULT %s;', $tbl, $col, $default),
        sprintf('UPDATE %s SET %s = %s;', $tbl, $col, $default);
    }
    if ($info->{not_null}) {
      my $not_null = sprintf 'ALTER TABLE %s ALTER COLUMN %s SET NOT NULL;', $tbl, $col;
      # after an UPDATE of the same transaction DuckDB cannot rebuild the
      # table's indexes ("Cannot create index with outstanding updates"), so
      # this one waits for the transaction of the rest (late_sql)
      if (defined $default && !$constant) { $late = $not_null }
      else                                { push @stmts, $not_null }
    }
    return (join("\n", @stmts), $late);
  }

  if ($self->action eq 'drop') {
    return (sprintf('ALTER TABLE %s DROP COLUMN %s;', $tbl, $col), '');
  }

  if ($self->action eq 'alter') {
    my $old = $self->old_info;
    my $new = $self->new_info;
    my @stmts;

    if (norm_type($old->{data_type}) ne norm_type($new->{data_type})) {
      push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET DATA TYPE %s;',
        $tbl, $col, ($new->{data_type} || 'VARCHAR');
    }
    if (($old->{not_null} // 0) != ($new->{not_null} // 0)) {
      push @stmts, $new->{not_null}
        ? sprintf('ALTER TABLE %s ALTER COLUMN %s SET NOT NULL;', $tbl, $col)
        : sprintf('ALTER TABLE %s ALTER COLUMN %s DROP NOT NULL;', $tbl, $col);
    }
    my $old_d = defined $old->{default_value} ? $old->{default_value} : '';
    my $new_d = defined $new->{default_value} ? $new->{default_value} : '';
    if ($old_d ne $new_d) {
      push @stmts, length $new_d
        ? sprintf('ALTER TABLE %s ALTER COLUMN %s SET DEFAULT %s;', $tbl, $col, $new_d)
        : sprintf('ALTER TABLE %s ALTER COLUMN %s DROP DEFAULT;', $tbl, $col);
    }
    return (join("\n", @stmts), '');
  }
}


our %LOSSLESS_PAIRS;
{
  my @signed   = qw(TINYINT SMALLINT INTEGER BIGINT HUGEINT);
  my @unsigned = qw(UTINYINT USMALLINT UINTEGER UBIGINT);
  for my $ladder (\@signed, \@unsigned) {
    for my $from (0 .. $#$ladder - 1) {
      $LOSSLESS_PAIRS{lc "$ladder->[$from]->$ladder->[$_]"} = 1 for $from + 1 .. $#$ladder;
    }
  }
  # an unsigned integer fits every signed one of more bits
  for my $at (0 .. $#unsigned) {
    $LOSSLESS_PAIRS{lc "$unsigned[$at]->$_"} = 1 for @signed[$at + 1 .. $#signed];
  }
  $LOSSLESS_PAIRS{'date->timestamp'} = 1;
}


sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  return column_change_lossy(
    _sized($self->old_info), _sized($self->new_info), \%LOSSLESS_PAIRS,
  ) ? 1 : 0;
}

# The info as column_change_lossy reads it: the base type, and the precision
# and scale of DECIMAL(p,s) as the size.
sub _sized {
  my ($info) = @_;
  $info ||= {};
  my $type = $info->{data_type};
  return { %$info } unless defined $type;
  return { %$info, data_type => $1, size => [ $2, $3 // 0 ] }
    if $type =~ /\A\s*(\w+)\s*\(\s*(\d+)\s*(?:,\s*(\d+)\s*)?\)\s*\z/;
  return { %$info };
}


sub summary {
  my ($self) = @_;
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s',
    $self->summary_prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Diff::Column - Diff operations for DuckDB columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Column-level diff operations for DuckDB. Unlike SQLite, DuckDB has a
reasonably complete C<ALTER TABLE>:

=over 4

=item * C<ALTER TABLE ... ADD COLUMN>

=item * C<ALTER TABLE ... DROP COLUMN>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET DATA TYPE>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET / DROP NOT NULL>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET / DROP DEFAULT>

=back

C<ADD COLUMN> takes a constant default only. A column that is C<NOT NULL>, or
has an expression default, is added in steps: the column, then C<SET DEFAULT>
and an C<UPDATE> that gives the rows already there the default, then
C<SET NOT NULL>. A C<NOT NULL> column without a default over a table that holds
rows, and a column that becomes C<NOT NULL> over C<NULL>s, are refused by
L<DBIO::DuckDB::Deploy/_check_before_apply> before the first statement.

So actual type and nullability changes are emitted as real ALTER statements
rather than commented-out warnings.

Brand-new tables get their columns inline via L<DBIO::DuckDB::Diff::Table>
-- this module only sees columns of tables that exist in both models.

=head1 ATTRIBUTES

=head2 lossless_pairs

    my %pairs = %DBIO::DuckDB::Diff::Column::LOSSLESS_PAIRS;

The changes of C<data_type> that DuckDB carries out without loss, as the
C<< old->new >> keys L<DBIO::Diff::Compare/column_change_lossy> reads. Each
pair was measured on libduckdb 1.5.3 (C<ALTER ... SET DATA TYPE> over the
boundary values of the old type, read back through a cast to it): the signed
integers to a wider one (C<TINYINT> E<lt> C<SMALLINT> E<lt> C<INTEGER> E<lt>
C<BIGINT> E<lt> C<HUGEINT>), the unsigned ones to a wider one
(C<UTINYINT> to C<UBIGINT>), an unsigned integer to a signed one of more bits,
and C<DATE> to C<TIMESTAMP> (midnight). Every other pair is lossy, in doubt it
is: a number to C<VARCHAR> or C<JSON> rewrites it, C<FLOAT> to C<DOUBLE>
alters the decimal reading, an integer to C<DECIMAL> fails when it does not
fit, C<TIMESTAMP> and C<TIMESTAMPTZ> depend on the session's time zone, and
anything from C<VARCHAR> is parsed. C<DECIMAL(p,s)> to C<DECIMAL(p2,s)> with
C<p2> at least C<p> is lossless through the size comparison.

=head1 METHODS

=head2 diff

=head2 as_sql

=head2 early_sql

=head2 late_sql

C<as_sql> in two parts. C<late_sql> is the C<SET NOT NULL> of a column that was
added with an expression default: DuckDB cannot run it in the transaction that
holds the C<UPDATE> filling the rows ("Cannot create index with outstanding
updates"). L<DBIO::DuckDB::Deploy/_execute_diff> runs C<early_sql> of every operation
in one transaction and the C<late_sql> parts after it. Empty for every other
operation.

=head2 lossy

True for an C<alter> that can alter or lose stored values, so that
L<DBIO::Deploy::Base/apply> runs it only with C<allow_destructive>.
The answer is L<DBIO::Diff::Compare/column_change_lossy> over the types of the
two columns with the pairs of L</lossless_pairs>; the precision and scale of a
C<DECIMAL(p,s)> are read as its size. A change of C<NOT NULL> and of the
default keeps every value (C<NOT NULL> over a C<NULL> is refused by
L<DBIO::DuckDB::Deploy/_check_before_apply>). Other actions are not lossy.

=head2 summary

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
