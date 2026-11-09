package DBIO::Firebird::Diff::Column;
# ABSTRACT: Diff operations for Firebird columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::Firebird::DDL qw(_firebird_quote_ident _firebird_column_clauses);
use DBIO::Firebird::Type qw(render_size);
use DBIO::Diff::Compare qw(changed_fields norm_type column_change_lossy);


# new() and the action accessor come from DBIO::Diff::Op.
__PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info constraints/);


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables,
      $source_uniques, $source_fks) = @_;
  my @ops;

  for my $table_name (sort keys %$target_cols) {
    next unless exists $source_tables->{$table_name}
             && exists $target_tables->{$table_name};
    # A view's columns are not a table's: no ALTER TABLE on a view. A view that
    # differs is Diff::Table's refusal (karr k33).
    next if ($source_tables->{$table_name}{kind} // '') eq 'view'
         || ($target_tables->{$table_name}{kind} // '') eq 'view';

    my %src_by_name = map { $_->{column_name} => $_ } @{ $source_cols->{$table_name} // [] };
    my %tgt_by_name = map { $_->{column_name} => $_ } @{ $target_cols->{$table_name} // [] };

    for my $col_name (sort keys %tgt_by_name) {
      my $tgt = $tgt_by_name{$col_name};

      if (!exists $src_by_name{$col_name}) {
        push @ops, $class->new(
          action      => 'add',
          table_name  => $table_name,
          column_name => $col_name,
          new_info    => $tgt,
        );
        next;
      }

      my $src = $src_by_name{$col_name};
      # Target is the desired state: fields absent from it are left as-is
      # (desired_state => 1). Firebird size may be a scalar length or a
      # [precision, scale] pair -- the `dim` field handles both.
      my $changed = changed_fields($src, $tgt,
        type   => ['data_type'],
        scalar => ['default_value'],
        bool   => ['not_null', 'is_auto_increment'],
        dim    => ['size'],
        desired_state => 1,
      );

      # The target is an introspected model, which carries default_value for
      # every column, undef where there is none: there undef is "no default",
      # not "no opinion" as changed_fields takes it. A model without the key
      # (hand made) still says nothing (karr k60).
      $changed ||= exists $tgt->{default_value}
        && !defined $tgt->{default_value}
        && defined $src->{default_value}
        && length $src->{default_value};

      if ($changed) {
        push @ops, $class->new(
          action      => 'alter',
          table_name  => $table_name,
          column_name => $col_name,
          old_info    => $src,
          new_info    => $tgt,
          constraints => _constraints_of($table_name, $col_name, $src,
                           $source_uniques, $source_fks),
        );
      }
    }

    for my $col_name (sort keys %src_by_name) {
      next if exists $tgt_by_name{$col_name};
      push @ops, $class->new(
        action      => 'drop',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $src_by_name{$col_name},
      );
    }
  }

  return @ops;
}

# The constraints of the source model that use a column, as the words the error
# message puts them in. The primary key is the column's own is_pk.
sub _constraints_of {
  my ($table, $column, $info, $uniques, $fks) = @_;
  my @found;

  push @found, 'PRIMARY KEY' if $info->{is_pk};

  for my $unique (@{ $uniques->{$table} // [] }) {
    my ($name, $columns) = @$unique;
    push @found, sprintf 'UNIQUE constraint %s', _firebird_quote_ident($name)
      if grep { $_ eq $column } @{ $columns // [] };
  }

  for my $fk (@{ $fks->{$table} // [] }) {
    push @found, sprintf 'FOREIGN KEY %s', _firebird_quote_ident($fk->{constraint_name} // '')
      if grep { $_ eq $column } @{ $fk->{from_columns} // [] };
  }

  return \@found;
}

# What the server stores a type in, for the rules below. Undef for a type (or a
# size) this module has no opinion on.
my %STORAGE_OF = (
  smallint => 'SMALLINT', integer => 'INTEGER', bigint => 'BIGINT', int128 => 'INT128',
  float => 'FLOAT', 'double precision' => 'DOUBLE',
  date => 'DATE', time => 'TIME', timestamp => 'TIMESTAMP', boolean => 'BOOLEAN',
  blob => 'BLOB', 'blob sub_type text' => 'BLOB',
  char => 'CHAR', varchar => 'CHAR', binary => 'CHAR', varbinary => 'CHAR',
);

# The storage a type is converted within. Measured on Firebird 5.0.4: the
# server converts to the same or a wider one, per this table, and to no other.
my %CONVERTS_TO = (
  SMALLINT  => [qw/SMALLINT INTEGER BIGINT INT128 FLOAT DOUBLE CHAR/],
  INTEGER   => [qw/INTEGER BIGINT INT128 DOUBLE CHAR/],
  BIGINT    => [qw/BIGINT INT128 CHAR/],
  INT128    => [qw/INT128 CHAR/],
  FLOAT     => [qw/FLOAT DOUBLE CHAR/],
  DOUBLE    => [qw/DOUBLE CHAR/],
  DATE      => [qw/DATE TIMESTAMP CHAR/],
  TIME      => [qw/TIME CHAR/],
  TIMESTAMP => [qw/TIMESTAMP DATE TIME CHAR/],
  BOOLEAN   => [qw/BOOLEAN/],
  CHAR      => [qw/CHAR/],
  BLOB      => [],
);

# The characters the text of each type needs when it goes into a CHAR/VARCHAR.
my %TEXT_LENGTH = (
  SMALLINT => 6, INTEGER => 11, BIGINT => 20, INT128 => 47,
  FLOAT => 15, DOUBLE => 24, DATE => 10, TIME => 13, TIMESTAMP => 25,
);

# ( storage, [precision, scale] or undef ) of a model column; empty for a type
# this module has no opinion on.
sub _storage {
  my ($info) = @_;
  my $type = lc norm_type($info->{data_type});
  my $size = $info->{size};

  if ($type eq 'numeric' || $type eq 'decimal') {
    return unless ref $size eq 'ARRAY' && defined $size->[0];
    my ($p, $s) = ($size->[0], $size->[1] // 0);
    # NUMERIC(1..4) is a SMALLINT; DECIMAL(1..9) is at least an INTEGER.
    my $storage = $p <= 4 && $type eq 'numeric' ? 'SMALLINT'
                : $p <= 9                       ? 'INTEGER'
                : $p <= 18                      ? 'BIGINT'
                :                                 'INT128';
    return ($storage, [ $p, $s ]);
  }

  my $storage = $STORAGE_OF{$type} or return;
  return ($storage, undef);
}

# A type the way an error message names it: "varchar(150)", "decimal(10,2)".
sub _type_text {
  my ($info) = @_;
  return lc(norm_type($info->{data_type}) || 'varchar') . render_size($info->{size})
    . ($info->{is_auto_increment} ? ' identity' : '');
}


sub refusal {
  my ($self) = @_;
  return unless ($self->action // '') eq 'alter';

  my ($old, $new) = ($self->old_info, $self->new_info);

  # IDENTITY is not something an existing column gains, loses or changes by an
  # ALTER here (karr k46): nothing in the Firebird column syntax this module
  # writes does it, and ALTER ... ADD of an identity column is refused by the
  # server on a table that holds rows. Refused before any statement runs.
  if (($old->{is_auto_increment} // 0) != ($new->{is_auto_increment} // 0)) {
    return $new->{is_auto_increment}
      ? 'the column is not an identity column and DBIO::Firebird does not turn an existing '
      . 'column into one (no ALTER is written for it; adding an identity column to a table '
      . 'that holds rows is refused by the server)'
      : 'the column is an identity column and DBIO::Firebird does not remove IDENTITY from an '
      . 'existing column (no ALTER is written for it)';
  }

  # No type change, no refusal: nullability and default are never refused.
  return unless norm_type($old->{data_type}) ne norm_type($new->{data_type})
             || changed_fields($old, $new, dim => ['size']);

  # The constraint rule stands before the type rules: it holds for a widening.
  if (my @keys = @{ $self->constraints // [] }) {
    return sprintf
      'the column is used by %s; the server refuses to change the type of such a column '
    . '("Cannot update index segment used by an Integrity Constraint"), whatever the change',
      join ', ', @keys;
  }

  my ($from, $from_dim) = _storage($old) or return;
  my ($to,   $to_dim)   = _storage($new) or return;

  if ($from eq 'BLOB' || $to eq 'BLOB') {
    return 'the server does not change the type of a BLOB column, nor convert anything into one';
  }
  if ($from eq 'CHAR' && $to ne 'CHAR') {
    return 'the server does not turn a character type into a non-character type';
  }
  if ($to eq 'BOOLEAN' && $from ne 'BOOLEAN') {
    return 'the server does not convert anything into BOOLEAN';
  }
  if (!grep { $_ eq $to } @{ $CONVERTS_TO{$from} }) {
    return "the server has no conversion from base type $from to $to";
  }

  if ($from eq 'CHAR' && $to eq 'CHAR') {
    my ($was, $is) = ($old->{size}, $new->{size});
    if (defined $was && defined $is && !ref $was && !ref $is && $is < $was) {
      return "the server never narrows a character column ($was characters to $is)";
    }
    return;
  }

  if ($from_dim && $to_dim) {
    my $was = $from_dim->[0] - $from_dim->[1];
    my $is  = $to_dim->[0]   - $to_dim->[1];
    if ($is < $was) {
      return "the digits before the decimal point would shrink from $was to $is "
           . '(precision minus scale); the server refuses that';
    }
  }

  if ($to eq 'CHAR' && !ref $new->{size} && defined $new->{size}) {
    my $needs = $TEXT_LENGTH{$from} // return;
    $needs++ if $from_dim && $from_dim->[1] > 0;
    if ($new->{size} < $needs) {
      return "a $from needs at least $needs characters as text, the new column has $new->{size}";
    }
  }

  return;
}

# The text of the error for a list of refused column operations.
sub refusal_error {
  my ($class, @ops) = @_;

  my @found = map {
    sprintf '  %s.%s: %s -> %s%s',
      _firebird_quote_ident($_->table_name), _firebird_quote_ident($_->column_name),
      _type_text($_->old_info), _type_text($_->new_info),
      "\n      " . $_->refusal;
  } @ops;

  return join "\n",
    sprintf(
      'refusing to change %d column%s: the Firebird server refuses %s',
      scalar @ops, (@ops == 1 ? ('', 'this change') : ('s', 'these changes')),
    ),
    '',
    @found,
    '',
    'The server refuses these whatever the table holds, so the statement would',
    'fail on it with the server\'s own error and leave an upgrade half applied.',
    'No statement was generated. The difference is still reported by diff,',
    'has_changes and summary. DBIO::Firebird does not rebuild the column',
    '(new column, copy, drop, rename); that is yours to do, or to give up.',
    # throw() takes one newline off and appends where it was called from.
    '', '';
}


sub as_sql {
  my ($self) = @_;

  if ($self->refusal) {
    DBIO::Exception->throw(ref($self)->refusal_error($self));
  }

  my $tbl = _firebird_quote_ident($self->table_name);
  my $col = _firebird_quote_ident($self->column_name);

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $type = $info->{data_type} || 'VARCHAR';
    my $sql  = sprintf 'ALTER TABLE %s ADD %s %s%s', $tbl, $col, $type,
      render_size($info->{size});
    $sql .= _firebird_column_clauses(
      identity => $info->{is_auto_increment},
      default  => $info->{default_value},
      not_null => $info->{not_null},
    );
    return "$sql;";
  }

  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP %s;', $tbl, $col;
  }

  if ($self->action eq 'alter') {
    my $old = $self->old_info;
    my $new = $self->new_info;
    my @stmts;

    # The size is part of the type: a changed size alone is a TYPE change too.
    # Compared the way diff() compares it, so a size the target does not
    # prescribe is not a change here either.
    if (norm_type($old->{data_type}) ne norm_type($new->{data_type})
        || changed_fields($old, $new, dim => ['size'])) {
      push @stmts, sprintf 'ALTER TABLE %s ALTER %s TYPE %s%s;',
        $tbl, $col, ($new->{data_type} || 'VARCHAR'), render_size($new->{size});
    }
    if (($old->{not_null} // 0) != ($new->{not_null} // 0)) {
      push @stmts, $new->{not_null}
        ? sprintf('ALTER TABLE %s ALTER %s SET NOT NULL;', $tbl, $col)
        : sprintf('ALTER TABLE %s ALTER %s DROP NOT NULL;', $tbl, $col);
    }
    my $old_d = defined $old->{default_value} ? $old->{default_value} : '';
    my $new_d = defined $new->{default_value} ? $new->{default_value} : '';
    if ($old_d ne $new_d) {
      push @stmts, length $new_d
        ? sprintf('ALTER TABLE %s ALTER %s SET DEFAULT %s;', $tbl, $col, $new_d)
        : sprintf('ALTER TABLE %s ALTER %s DROP DEFAULT;', $tbl, $col);
    }
    return join "\n", @stmts;
  }
}


our %LOSSLESS_PAIRS;
{
  my @ladder = qw(smallint integer bigint int128);
  for my $from (0 .. $#ladder - 1) {
    $LOSSLESS_PAIRS{"$ladder[$from]->$ladder[$_]"} = 1 for $from + 1 .. $#ladder;
  }
  $LOSSLESS_PAIRS{"$_->double precision"} = 1 for qw(smallint integer);
  $LOSSLESS_PAIRS{'date->timestamp'}      = 1;
  $LOSSLESS_PAIRS{'char->varchar'}        = 1;
  $LOSSLESS_PAIRS{'binary->varbinary'}    = 1;
}


sub lossy_pairs { return { %LOSSLESS_PAIRS } }


sub lossy {
  my ($self) = @_;
  return 0 unless ($self->action // '') eq 'alter';
  my ($old, $new) = ($self->old_info // {}, $self->new_info // {});

  my @pair = map { lc norm_type($_->{data_type}) } $old, $new;
  $pair[1] = $pair[0] unless length $pair[1];

  # A CHAR is stored padded to its length and the server pads it to the new
  # length when it becomes a VARCHAR of another one (measured, t/99-diff-
  # column-lossless-live.t: char(5) 'ab' reads 'ab   ' as varchar(5) and
  # 'ab       ' as varchar(9)): only the same length keeps the value.
  if ($pair[0] ne $pair[1] && $pair[0] =~ /\A(?:char|binary)\z/) {
    my ($was, $is) = ($old->{size}, $new->{size});
    return 1 if defined $is && (ref $is || ref($was // '') || !defined $was || $is != $was);
  }

  return column_change_lossy($old, $new, \%LOSSLESS_PAIRS) ? 1 : 0;
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

DBIO::Firebird::Diff::Column - Diff operations for Firebird columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Column-level diff operations for Firebird. An op renders as one of

    ALTER TABLE "t" ADD "c" varchar(100) DEFAULT 'x' NOT NULL;
    ALTER TABLE "t" DROP "c";
    ALTER TABLE "t" ALTER "c" TYPE decimal(12,3);
    ALTER TABLE "t" ALTER "c" SET NOT NULL;      -- or DROP NOT NULL
    ALTER TABLE "t" ALTER "c" SET DEFAULT 'x';   -- or DROP DEFAULT

Table and column are always double-quoted (see
L<DBIO::Firebird::DDL/install_ddl> for why), and the type always carries the
model's C<size>, rendered by L<DBIO::Firebird::Type/render_size>: the size is
part of the type, so a changed length or a changed C<(precision,scale)> is an
C<ALTER ... TYPE> like a changed type name is. In an C<ADD> the default comes
before C<NOT NULL>; Firebird parses the two in that order only.

The statement is the plain one for the difference found -- unless the server
is known to refuse it. See L</COLUMN CHANGES THE SERVER REFUSES>.

=head1 ATTRIBUTES

=head2 lossy_pairs

    my %pairs = %DBIO::Firebird::Diff::Column::LOSSLESS_PAIRS;

The C<< old->new >> keys L</lossy> hands to
L<DBIO::Diff::Compare/column_change_lossy>; see L</COLUMN CHANGES THAT CAN LOSE
DATA>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Firebird::Diff::Column->diff(
      $source_cols, $target_cols, $source_tables, $target_tables,
      $source_unique_constraints, $source_foreign_keys);

The last two arguments are the C<unique_constraints> and C<foreign_keys>
sections of the I<source> model. They tell an C<alter> operation which
constraints use its column (see L</COLUMN CHANGES THE SERVER REFUSES>); left
out, only the C<is_pk> of the column counts.

=head2 refusal

    my $reason = $op->refusal;    # undef, or why the server refuses

For an C<alter> operation that changes the type or size of a column: the
reason the Firebird server always refuses the change, as one line of text, or
undef if it takes it (or if this module has no rule for it). See
L</COLUMN CHANGES THE SERVER REFUSES>. Every other operation returns undef.

=head2 as_sql

Dies with a L<DBIO::Exception> instead of returning a statement for an
C<alter> that L</refusal> gives a reason for.

=head2 lossy

    my $lossy = $op->lossy;

True for an C<alter> whose type or size can alter or lose stored values
(L</COLUMN CHANGES THAT CAN LOSE DATA>); false for everything else.

=head2 summary

=head1 COLUMN CHANGES THE SERVER REFUSES

Firebird does not accept every type change. It widens a C<VARCHAR> and refuses
to narrow one, does not turn a character column into a numeric one, does not
retype a column a constraint depends on. Sent anyway, such a statement dies on
the server with its own message, C<upgrade> stops half way, and the same
difference is back on the next run. So the diff refuses them itself,
earlier and clearer.

B<The difference is still reported.> C<diff> returns the operation,
C<has_changes> is true and C<summary> lists the column. What refuses is
generating the statement: C<as_sql> of the operation, and so
L<DBIO::Firebird::Diff/as_sql>, L<DBIO::Deploy::Base/apply> and
L<DBIO::Deploy::Base/upgrade>, die with a L<DBIO::Exception> naming table,
column, old and new type and the reason -- for I<every> such column of the
diff at once. C<apply> renders the whole script before it executes its first
statement, so nothing of an upgrade that contains a refused change runs.

Only what the server I<always> refuses is refused. The rules were measured
against Firebird 5.0.4, each case on an empty table and on one with rows (the
answer did not differ), and t/28-diff-column-refused-live.t walks the
predicate against a server, pair by pair. The type of a column is changed only
if it is none of these:

=over 4

=item * Narrowing C<CHAR> / C<VARCHAR> (and C<BINARY> / C<VARBINARY>): a new
length below the old one. Widening, and C<CHAR> to C<VARCHAR> of the same
length, are accepted.

=item * A character type to anything that is not a character type; and
anything to C<BOOLEAN> or to a C<BLOB>, and a C<BLOB> to anything else.

=item * A conversion between the other types the server has none of. It
converts within the storage, never to a smaller one: C<SMALLINT> to
C<INTEGER>, C<BIGINT>, C<INT128>, C<FLOAT>, C<DOUBLE>; C<INTEGER> to
C<BIGINT>, C<INT128>, C<DOUBLE>; C<BIGINT> to C<INT128>; C<FLOAT> to C<DOUBLE>;
C<DATE> and C<TIMESTAMP> to each other; C<TIMESTAMP> to C<TIME>. Not
C<BIGINT> to C<INTEGER>, not C<DATE> to C<TIME>, not C<DOUBLE> to C<FLOAT>.
C<NUMERIC> and C<DECIMAL> count as the integer they are stored in:
C<NUMERIC(1..4)> is a C<SMALLINT>, C<NUMERIC(5..9)> and C<DECIMAL(1..9)> an
C<INTEGER>, up to 18 digits a C<BIGINT>, beyond that an C<INT128>.

=item * A C<NUMERIC> / C<DECIMAL> that has fewer digits before the decimal
point (precision minus scale) than before. Lowering the scale alone, or
raising precision, is accepted -- and so is raising the scale as long as the
digits before the point do not shrink. (The maintainer's card expected a
lowered scale to be refused; the server takes it.)

=item * A non-character type into a C<CHAR> / C<VARCHAR> too short for its
text: C<SMALLINT> 6, C<INTEGER> 11, C<BIGINT> 20, C<INT128> 47 (one more for a
numeric with a scale), C<FLOAT> 15, C<DOUBLE PRECISION> 24, C<DATE> 10, C<TIME>
13, C<TIMESTAMP> 25.

=item * Adding, removing or changing C<IDENTITY> on a column that exists: C<is_auto_increment> differs between the live and the target
model. Nothing here writes an ALTER for it, and the server refuses an identity
column added to a table that holds rows (measured on Firebird 5.0.4: "Cannot
make field NOT NULL because there are NULLs present"). A new column that is an
identity column is a plain C<ADD ... GENERATED BY DEFAULT AS IDENTITY>, which
the server takes on an empty table; so is the column of a new table.

=item * Any type change of a column that is in the C<PRIMARY KEY>, in a
C<UNIQUE> constraint or in a C<FOREIGN KEY> of the source (live) model: the
server answers I<Cannot update index segment used by an Integrity Constraint>,
even for a widening, even on an empty table. An ordinary index does not hold
the type; its column is changed like any other. The membership is read from
the model sections the diff already has (C<is_pk> of the column,
C<unique_constraints>, C<foreign_keys>), so a column in a C<UNIQUE INDEX>
that is not a constraint is not a key here either.

=back

A type or size the target does not prescribe is no opinion: a size the target
leaves out is not compared (see C<changed_fields>), and a rule that needs it
does not fire. The default is different: the target of the diff is an
introspected model, which carries C<default_value> for every column and has
C<undef> where the column has none, so there C<undef> means I<no default>. A
column that has a default in the database and none in the target gets
C<ALTER ... DROP DEFAULT>. A hand-made target model without the key
C<default_value> says nothing about it and leaves the default alone. A type this module has no rule for (C<DECFLOAT>, the
time zone types) is never refused.

There is no rebuild: nothing here adds a column, copies and renames. A refused
change is something to do by hand -- or to give up -- and the error says which.

=head1 COLUMN CHANGES THAT CAN LOSE DATA

A type or size change the server carries out can still round, cut or rewrite
the stored values. L</lossy> says which ones do, so that
L<DBIO::Deploy::Base/apply> runs them only with C<allow_destructive> (core ADR
0080). The answer is
L<DBIO::Diff::Compare/column_change_lossy> over the two columns with the type
pairs of C<%LOSSLESS_PAIRS>: the same type with a size at least as large (the
scale of a C<NUMERIC> / C<DECIMAL> equal), or one of the pairs below. Every
other change of type or size is lossy; in doubt it is.

=over 4

=item * C<smallint> to C<integer>, C<bigint>, C<int128>; C<integer> to
C<bigint>, C<int128>; C<bigint> to C<int128>: the integer types widen within
the exact numbers and every value keeps its digits.

=item * C<smallint> and C<integer> to C<double precision>: a double holds 53
bits exactly, so every 16 and 32 bit integer comes back as it went in.
C<bigint> and C<int128> do not fit and stay lossy; so does C<float>, which
holds 24 bits.

=item * C<date> to C<timestamp>: the date is the timestamp at midnight.

=item * C<char> to C<varchar>, C<binary> to C<varbinary> of the I<same>
length: the same bytes, padding included. With another length the server pads
the stored value to the new one (C<char(5)> C<'ab'> becomes C<'ab'> and seven
blanks as C<varchar(9)>), so the value changes and the change is lossy; a
smaller length is refused by the server besides.

=back

Not lossless, whatever the server accepts: C<float> to C<double precision>
(the decimal reading of a value changes), C<timestamp> to C<date> or C<time>
(the rest is cut), a number to a character type and the reverse (rewritten),
a C<NUMERIC> to a C<DECIMAL> or the reverse, and a larger scale. t/99 holds
the answer per pair; t/99-diff-column-lossless-live.t shows against a server
that the values of every lossless pair read back unchanged.

A change of C<NOT NULL> or of the default alone keeps every value and is not
lossy; C<NOT NULL> over a C<NULL> is refused by
L<DBIO::Firebird::Deploy/_refuse_unfillable>. Operations that are not an
C<alter> are not lossy.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
