package DBIO::MSSQL::Diff::Column;
# ABSTRACT: Diff operations for MSSQL columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();

use DBIO::MSSQL::DDL qw(_mssql_column_type _quote_ident _quote_table _bare_table);
use DBIO::MSSQL::Diff::Table ();
use DBIO::Diff::Compare qw(changed_column_fields column_change_lossy);


__PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;

  # a view has no ALTER TABLE ... ADD/DROP COLUMN; Diff::View replaces it (karr k82)
  my %is_view = map { $_ => 1 }
    DBIO::MSSQL::Diff::Table->view_names($source_tables, $target_tables);
  if (%is_view) {
    $source_cols = { map { $_ => $source_cols->{$_} } grep { !$is_view{$_} } keys %{ $source_cols // {} } };
    $target_cols = { map { $_ => $target_cols->{$_} } grep { !$is_view{$_} } keys %{ $target_cols // {} } };
  }

  return $class->diff_nested($source_cols, $target_cols,
    index_by      => 'column_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub { scalar changed_column_fields($_[0], $_[1]) },
    on_new => sub {
      my ($table, $name, $new) = @_;
      $class->new(action => 'add', table_name => $table, column_name => $name, new_info => $new);
    },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      $class->new(action => 'alter', table_name => $table, column_name => $name,
        old_info => $old, new_info => $new);
    },
    on_gone => sub {
      my ($table, $name, $old) = @_;
      $class->new(action => 'drop', table_name => $table, column_name => $name, old_info => $old);
    },
  );
}


our %LOSSLESS_PAIRS;
{
  my @ladder = qw(tinyint smallint int bigint);
  for my $from (0 .. $#ladder - 1) {
    $LOSSLESS_PAIRS{"$ladder[$from]->$ladder[$_]"} = 1 for $from + 1 .. $#ladder;
  }
  $LOSSLESS_PAIRS{'date->datetime2'} = 1;
}

# string types that become another one of the same content without loss while
# the length stays or grows
my %SAME_FAMILY = map { $_ => 1 } qw(
  char->varchar char->nchar char->nvarchar varchar->nvarchar nchar->nvarchar
  binary->varbinary
);

my %ALIAS = (integer => 'int', numeric => 'decimal', bool => 'bit', boolean => 'bit');


sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  return 0 unless $self->retypes;
  my ($old, $new) = ($self->old_info // {}, $self->new_info // {});

  my $base = sub { my $t = lc($_[0] // ''); $t =~ s/\s.*\z//s; $ALIAS{$t} // $t };
  my ($ot, $nt) = ($base->($old->{data_type}), $base->($new->{data_type}));
  $nt = $ot unless length $nt;

  # max is longer than any number
  my $len = sub {
    my $s = $_[0];
    return $s unless defined $s && !ref $s && $s =~ /\A\s*-1\s*\z/;
    return 2**31;
  };
  my %o = (data_type => $ot, size => $len->($old->{size}));
  my %n = (data_type => $nt, size => $len->($new->{size}));
  $n{data_type} = $ot if $SAME_FAMILY{"$ot->$nt"};

  return column_change_lossy(\%o, \%n, \%LOSSLESS_PAIRS) ? 1 : 0;
}


sub retypes {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  my $old = $self->old_info || {};
  my $new = $self->new_info || {};
  my $want = sub { defined $new->{$_[0]} ? $new->{$_[0]} : $old->{$_[0]} };
  my $dt = $want->('data_type');
  return 0 unless defined $dt && defined $old->{data_type};
  my $nt = $self->_alter_column_type({ data_type => $dt, size => $want->('size') }, 'desired');
  my $ot = $self->_alter_column_type($old, 'live');
  return $nt ne $ot ? 1 : 0;
}


sub unbinds_dependents {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  my $old = $self->old_info || {};
  my $new = $self->new_info || {};
  my $want = sub { defined $new->{$_[0]} ? $new->{$_[0]} : $old->{$_[0]} };
  my $new_nn = $want->('not_null') ? 1 : 0;
  return 1 if $new_nn && !$old->{not_null};
  my $dt = $want->('data_type');
  return 0 unless defined $dt && defined $old->{data_type};
  my $nt = $self->_alter_column_type({ data_type => $dt, size => $want->('size') }, 'desired');
  my $ot = $self->_alter_column_type($old, 'live');
  return 0 if $nt eq $ot;
  my ($nb) = lc($nt) =~ /\A(\w+)/;
  my ($ob) = lc($ot) =~ /\A(\w+)/;
  return 0 if $nb eq $ob && $nb =~ /\A(?:nvarchar|varchar|varbinary)\z/;
  return 1;
}


sub as_sql {
  my ($self) = @_;

  my $tbl = _quote_table($self->table_name);
  my $col = _quote_ident($self->column_name);

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $type = _mssql_column_type($info, $self->table_name, $self->column_name);
    my $sql  = sprintf 'ALTER TABLE %s ADD %s %s', $tbl, $col, $type;
    $sql .= ' NOT NULL' if $info->{not_null};
    if (defined $info->{default_value}) {
      $sql .= " DEFAULT $info->{default_value}";
    }
    return "$sql;";
  }

  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;', $tbl, $col;
  }

  if ($self->action eq 'alter') {
    my $old = $self->old_info || {};
    my $new = $self->new_info || {};
    my @stmts;

    # The desired state of one field, read the way the comparator that decided
    # this op exists reads it: a field the target leaves undef was not
    # prescribed, so the live value stands (DBIO::Diff::Compare, desired-state
    # contract). Per FIELD, not per hashref -- a target naming a type but no
    # size must keep the live length, because a bare nvarchar in a column
    # definition is not "unbounded", it is nvarchar(1) (karr k28).
    my $want = sub {
      my ($field) = @_;
      return defined $new->{$field} ? $new->{$field} : $old->{$field};
    };

    my %want_type = (data_type => $want->('data_type'), size => $want->('size'));
    my $old_nn = $old->{not_null}   ? 1 : 0;
    my $new_nn = $want->('not_null') ? 1 : 0;

    # The RENDERED type is the trigger, not the bare data_type string:
    # INFORMATION_SCHEMA keeps the width in CHARACTER_MAXIMUM_LENGTH, so
    # nvarchar(64) -> nvarchar(128) has the same data_type on both sides and
    # fell through every branch, leaving as_sql returning the empty string
    # while the diff still reported a change (karr k30).
    my ($retype, $new_type) = (0, undef);
    if (defined $want_type{data_type}) {
      $new_type = $self->_alter_column_type(\%want_type, 'desired');
      $retype   = !defined $old->{data_type}
               || $new_type ne $self->_alter_column_type($old, 'live');
    }

    # One statement, always carrying both -- see L</ALTER COLUMN IS ONE
    # STATEMENT>. Emitted only when something in it actually moved, so a
    # default-only change does not drag a pointless retype along.
    if ($retype || $old_nn != $new_nn) {
      DBIO::Exception->throw(sprintf(
        "DBIO::MSSQL: ALTER COLUMN of column '%s' of table '%s' (%s.%s) is "
          . 'refused: Transact-SQL requires a new_data_type there and neither '
          . 'the desired nor the live column info names one',
        $self->column_name, $self->table_name,
        $self->table_name, $self->column_name,
      )) unless defined $new_type;

      push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s %s %s;',
        $tbl, $col, $new_type, ($new_nn ? 'NOT NULL' : 'NULL');
    }

    # A default is a named CONSTRAINT in this dialect, never a clause of ALTER
    # COLUMN (karr k31). The drop is unshifted ahead of any retype because SQL
    # Server refuses to change the data type of a column that is "associated
    # with a default definition".
    my $new_d = $new->{default_value};
    if (defined $new_d && length $new_d) {
      my $old_d = $old->{default_value};
      if (!defined $old_d || $old_d ne $new_d) {
        if (defined $old_d && length $old_d) {
          my $live_name = $old->{default_constraint_name}
            or DBIO::Exception->throw(sprintf(
              "DBIO::MSSQL: replacing the DEFAULT of column '%s' of table '%s' "
                . '(%s.%s) is refused: Transact-SQL drops a default by '
                . 'CONSTRAINT NAME and the live column info carries no '
                . 'default_constraint_name',
              $self->column_name, $self->table_name,
              $self->table_name, $self->column_name,
            ));
          unshift @stmts, sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;',
            $tbl, _quote_ident($live_name);
        }
        push @stmts, sprintf 'ALTER TABLE %s ADD CONSTRAINT %s DEFAULT %s FOR %s;',
          $tbl, _quote_ident($self->_default_constraint_name($new)), $new_d, $col;
      }
    }

    # A default the target no longer declares is removed (core karr k367,
    # karr k83): the comparator reports it, the live name drops it. A live
    # DEFAULT NULL counts as none, as in the comparator.
    elsif (_is_real_default($old->{default_value})) {
      my $live_name = $old->{default_constraint_name}
        or DBIO::Exception->throw(sprintf(
          "DBIO::MSSQL: removing the DEFAULT of column '%s' of table '%s' "
            . '(%s.%s) is refused: Transact-SQL drops a default by '
            . 'CONSTRAINT NAME and the live column info carries no '
            . 'default_constraint_name',
          $self->column_name, $self->table_name,
          $self->table_name, $self->column_name,
        ));
      unshift @stmts, sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;',
        $tbl, _quote_ident($live_name);
    }

    return join "\n", @stmts;
  }
}

# True for a live default that is one: not absent, not a literal NULL
# ("(NULL)", "((NULL))", \'NULL'), the way DBIO::Diff::Compare reads it.
sub _is_real_default {
  my ($v) = @_;
  $v = $$v if ref($v) eq 'SCALAR' || ref($v) eq 'REF';
  return 0 unless defined $v;
  $v =~ s/\A\s+|\s+\z//g;
  1 while $v =~ s/\A\(\s*(.*?)\s*\)\z/$1/s;
  return length $v && uc($v) ne 'NULL' ? 1 : 0;
}

# _mssql_column_type with the column named in whatever it refuses. A type the
# renderer cannot produce has no silent fallback here: the bare type name it
# would otherwise return is a one-character column in T-SQL, so refusing is the
# only reading that does not quietly change the data model.
sub _alter_column_type {
  my ($self, $info, $side) = @_;
  my $type = eval { _mssql_column_type($info) };
  return $type if defined $type;
  my $err = $@ || "unknown error\n";
  $err =~ s/\s+\z//;
  DBIO::Exception->throw(sprintf
    "DBIO::MSSQL: ALTER COLUMN of column '%s' of table '%s' (%s.%s) is refused: "
    . 'cannot render the %s type: %s',
    $self->column_name, $self->table_name,
    $self->table_name, $self->column_name, $side, $err);
}

# The name the new DEFAULT constraint is created under. Named rather than left
# to the server so a later diff can drop it without introspection; a target
# that carries a name of its own keeps it.
sub _default_constraint_name {
  my ($self, $info) = @_;
  return $info->{default_constraint_name}
    if defined $info->{default_constraint_name} && length $info->{default_constraint_name};
  return sprintf 'DF_%s_%s', _bare_table($self->table_name), $self->column_name;
}


sub summary {
  my ($self) = @_;
  my $type = $self->new_info ? ' (' . $self->new_info->{data_type} . ')' : '';
  return sprintf '  %scolumn: %s.%s%s',
    $self->summary_prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Diff::Column - Diff operations for MSSQL columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Column-level diff operations for MSSQL. MSSQL supports C<ALTER TABLE ADD/DROP COLUMN>,
C<ALTER COLUMN> for type/nullability/default changes. Built on
L<DBIO::Diff::Op> (the nested create/change/drop walk) and
L<DBIO::Diff::Compare> (the C<changed_column_fields> sameness predicate).

=head1 ATTRIBUTES

=head2 lossy_pairs

    my %pairs = %DBIO::MSSQL::Diff::Column::LOSSLESS_PAIRS;

The changes of C<data_type> that SQL Server carries out without loss, as the
C<< old->new >> keys L<DBIO::Diff::Compare/column_change_lossy> reads: the
integer types to a wider one (C<tinyint> E<lt> C<smallint> E<lt> C<int> E<lt>
C<bigint>) and C<date> to C<datetime2>. The string types of one family
(C<char> to C<varchar>, C<nchar> to C<nvarchar>, C<char> to C<nchar>,
C<varchar> to C<nvarchar>, C<binary> to C<varbinary>) are lossless as long as
the length does not shrink (L</lossy>). Every other pair of types is lossy, in
doubt it is: C<datetime> to C<datetime2> exposes the 3.33 ms steps of the old
type, a number to a string rewrites it.

=head1 METHODS

=head2 diff

=head2 lossy

True for an C<alter> op that can alter or lose stored values, so that
L<DBIO::Deploy::Base/apply> runs it only with C<allow_destructive>.
The answer is L<DBIO::Diff::Compare/column_change_lossy> over the types and
lengths of the two columns, with the pairs of L</lossy_pairs>; a length of
C<max> (C<-1>) is longer than every number. An op whose rendered type does not
change (only nullability or the default) keeps every value and is not lossy;
C<NOT NULL> over a C<NULL> is refused by L<DBIO::MSSQL::Deploy/_refuse_unfillable>.
Other actions are not lossy.

=head2 retypes

True for an C<alter> op whose rendered type differs from the live one, a width
change included. SQL Server refuses such an C<ALTER COLUMN> while a foreign key
stands on the column, as the child column or as the referenced one (measured
2026-10-21, widths of C<nvarchar> too; a nullability change alone runs), so
L<DBIO::MSSQL::Diff> drops and creates again the foreign keys of the column.

=head2 unbinds_dependents

True for an C<alter> op the server refuses while an index or unique constraint
covers the column: the column becomes C<NOT NULL> or changes its type beyond a
width change of C<nvarchar>/C<varchar>/C<varbinary> (the cases measured to
work). Anything not known to work counts as true.

=head2 as_sql

=head2 summary

=head1 ALTER COLUMN IS ONE STATEMENT

An C<alter> op renders B<one> C<ALTER COLUMN> carrying the fully rendered type
I<and> an explicit C<NULL> / C<NOT NULL>, never a type statement and a
nullability statement side by side. Three facts from the Transact-SQL C<ALTER
TABLE> grammar force that shape:

=over 4

=item *

C<< ALTER COLUMN column_name type_name [ ( precision [, scale] | max | ... ) ]
[ COLLATE ... ] [ NULL | NOT NULL ] [ SPARSE ] >> -- the type is not optional in
that production, so a bare C<ALTER COLUMN a NOT NULL> is not a statement the
server can parse.

=item *

"If you specify C<NULL> or C<NOT NULL> with C<ALTER COLUMN>, you must also
specify I<new_data_type> [(I<precision> [, I<scale>])]. If the data type,
precision, and scale aren't changing, specify the current column values." So
repeating an unchanged type is not redundancy, it is what the grammar asks for.

=item *

"C<ANSI_NULL> defaults are always on for C<ALTER COLUMN>; if not specified, the
column is nullable." Leaving the nullability off an C<ALTER COLUMN> does not
preserve it -- it B<drops> it. Writing it every time is the only way a type
change keeps a C<NOT NULL>.

=back

The trigger for that statement is the B<rendered> type
(L<DBIO::MSSQL::DDL/_mssql_column_type>: length, precision/scale and C<(max)>
included), not the bare C<data_type> string. C<INFORMATION_SCHEMA> keeps the
width in C<CHARACTER_MAXIMUM_LENGTH>, so C<nvarchar(64)> and C<nvarchar(128)>
share a C<data_type>: comparing that string alone recognised no change and
returned the empty statement, while the comparator went on reporting one, and
the diff never converged. Comparing the rendered type also means two spellings
of one native type (C<varchar> and C<nvarchar> both render C<nvarchar> here)
produce no statement at all.

A column whose rendered type and nullability both stand still gets no
C<ALTER COLUMN>; a default-only change emits only the constraint DDL below.

=head1 DEFAULTS ARE CONSTRAINTS

There is no C<ALTER COLUMN ... SET DEFAULT> / C<DROP DEFAULT> in this dialect --
that is the ANSI/PostgreSQL spelling. A default is an object:

    ALTER TABLE t ADD CONSTRAINT DF_t_a DEFAULT ((0)) FOR a;
    ALTER TABLE t DROP CONSTRAINT DF__t__a__3B75D760;

New constraints are named C<< DF_<table>_<column> >> rather than left to the
server, so a later diff can address them without introspecting first. Dropping
one needs the B<live> name, which the model carries as
C<default_constraint_name> (see L<DBIO::MSSQL::Introspect::Columns>); without
it there is no correct statement to emit and this class refuses (throws a L<DBIO::Exception>) rather than
emit a plausible-looking one that removes nothing.

A default the target no longer declares (C<default_value> C<undef>) is removed:
core's comparator reports it and the op renders only the
C<DROP CONSTRAINT> by the live name. A live C<DEFAULT NULL> counts as
no default and is left alone. Dropping a whole column needs no such statement
from this class; the removal of a default is an C<alter> op.

When a default is replaced alongside a type change, the C<DROP CONSTRAINT> is
ordered B<before> the C<ALTER COLUMN> and the C<ADD CONSTRAINT> after it,
because SQL Server refuses to change the data type of a column that is
"associated with a default definition".

=head1 THE DESIRED-STATE CONTRACT APPLIES TO RENDERING TOO

C<as_sql> reads C<new_info> the way L<DBIO::Diff::Compare/changed_fields> reads
it when deciding this op exists at all: a field the target leaves C<undef> was
not prescribed, so the live value stands. That is applied per B<field>, not per
hashref -- a target naming a type but no size keeps the live length, because a
bare C<nvarchar> in a column definition is not "unbounded", it is
C<nvarchar(1)>.

Two consequences worth stating plainly:

=over 4

=item *

A target that does not prescribe C<not_null> keeps the live nullability instead
of defaulting to nullable.

=item *

"This column should have B<no> default" is expressible: the comparator reports
a live default the target leaves C<undef> as changed, and the
op drops the live constraint (see L</DEFAULTS ARE CONSTRAINTS>).

=back

=head1 DEPENDENT INDEXES AND UNIQUE CONSTRAINTS

Measured live (2026-10-20, MSSQL 2022): C<ALTER COLUMN> fails ("The object
'UQ_t' is dependent on column 'uq'", "The index 'ix1' is dependent on ...")
on a column in a unique constraint, a unique index or a nonclustered index when
the column goes from C<NULL> to C<NOT NULL> or changes its type. These work:
C<NOT NULL> to C<NULL>, a width change of C<nvarchar>/C<varchar>/C<varbinary>,
and a nullability change of a foreign key column. Any retype of a foreign key
column, a width change included, is refused while the key stands ("The object
'FK' is dependent on column", on the child column and on the referenced one;
L</retypes>); the foreign key phases of L<DBIO::MSSQL::Diff> handle that.
L</unbinds_dependents> says whether an C<alter> op is one of the failing kind;
L<DBIO::MSSQL::Diff> then drops the indexes and unique constraints of the
column before the column phase and creates them again after it.

=head1 LIMITS

Every statement here is written against the documented grammar; none of it has
been executed against a server (this driver's live suite does not exercise the
introspect/diff path). What a live run would still have to confirm: that
C<sys.default_constraints> reports the names as assumed, and that the emitted
statements are accepted in the order they are emitted.

Independent of spelling, SQL Server refuses C<ALTER COLUMN> on a column that
other objects depend on -- one used in a C<PRIMARY KEY> / C<FOREIGN KEY>, in a
C<CHECK> or C<UNIQUE> constraint, in an index (beyond a plain width change), or
associated with a default definition. This class removes the default dependency
only when it is I<replacing> that default; indexes and unique constraints are
handled by L<DBIO::MSSQL::Diff> (see above); the others it does not address at
all, and a diff that runs into one fails loudly at the server.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
