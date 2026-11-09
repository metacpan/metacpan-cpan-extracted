package DBIO::SQLite::Diff::Column;
# ABSTRACT: Diff operations for SQLite columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Carp ();
use Scalar::Util qw(refaddr);
use DBIO::Diff::Compare qw(changed_column_fields column_change_lossy);
use DBIO::SQLite::Util qw(
  create_table_name_index default_value_sql quote_identifier sql_tokens
  token_identifier type_affinity type_with_size
);
use namespace::clean;


# The groups of type names that share one affinity. Each name is the lower
# case data_type; a pair is lossless when both names are in one group
# (t/74-diff-column-lossy.t checks the groups against type_affinity and the
# pairs against the rows SQLite really copies).
my %AFFINITY_GROUP = (
  INTEGER => [ qw(integer int bigint smallint tinyint mediumint int2 int8) ],
  TEXT    => [ qw(text varchar char character nchar nvarchar clob) ],
  REAL    => [ 'real', 'double', 'double precision', 'float' ],
  NUMERIC => [ qw(numeric decimal boolean date datetime) ],
  BLOB    => [ 'blob', '' ],
);

my %LOSSLESS_PAIRS;
for my $names (values %AFFINITY_GROUP) {
  for my $from (@$names) {
    for my $to (@$names) {
      $LOSSLESS_PAIRS{"$from->$to"} = 1 unless $from eq $to;
    }
  }
}


sub lossless_type_pairs { return { %LOSSLESS_PAIRS } }


sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  return column_change_lossy($self->old_info, $self->new_info, \%LOSSLESS_PAIRS) ? 1 : 0;
}

__PACKAGE__->mk_diff_accessors(qw/
  table_name column_name old_info new_info definition needs_rebuild
  target_described
/);


# What a CREATE TABLE statement declares, as far as an added column needs it
# and as far as no PRAGMA reports it:
#
#   columns     => { $name => {
#     sql       => 'TYPE and constraints',
#     keyed     => 0|1,
#     checks    => [ 'qty >= 0', ... ],     # its CHECK clauses, sorted
#     collate   => 'nocase' | undef,        # its COLLATE, lower case
#     generated => 'a + b VIRTUAL' | undef, # its generated clause
#   } }
#   constrained => { lc $name => 1 }
#   checks      => [ 'low <= high', ... ]   # the table's CHECK constraints
#
# keyed says the column's own definition carries PRIMARY KEY or UNIQUE;
# constrained holds every name a table constraint mentions, short of the
# column list a FOREIGN KEY points at. Returns nothing for a statement it
# cannot follow -- the caller rebuilds the table then, it does not guess.
#
# checks, collate and generated are what DBIO::SQLite::Diff compares on a
# table both sides have (karr k72). An expression is its tokens joined by one
# space, without whitespace and comments and without the parentheses around
# it: what is written is compared, not what it means. The keywords that frame
# a clause -- CHECK, COLLATE, GENERATED ALWAYS AS, STORED, VIRTUAL -- are read
# in any letter case, and so is the name of a collation, which SQLite does not
# tell apart by case. A constraint's name is not kept.
#
# The statement is read with the driver's one lexer (DBIO::SQLite::Util's
# sql_tokens), which tells a quoted name from a word. So it does not matter
# how the statement quotes its names: bare, as a database deployed by an
# earlier version has them, or all in double quotes, as DBIO::SQLite::DDL
# writes them now -- a column named "unique" or "check" included.
# The parenthesised group that begins at or behind $tokens->[$from], as
# ($text, $index_of_its_closing_parenthesis). An opening parenthesis carries
# the depth of what is inside it and the closing one the depth outside, so the
# group ends at the first ")" one level up. Nothing when there is no group.
sub _group {
  my ($tokens, $from) = @_;
  $from++ while $tokens->[$from] && $tokens->[$from][0] eq 'skip';
  my $open = $tokens->[$from];
  return unless $open && $open->[0] eq 'punct' && $open->[1] eq '(';

  my @inner;
  for my $at ($from + 1 .. $#$tokens) {
    my ($kind, $text, $depth) = @{ $tokens->[$at] };
    return (join(' ', @inner), $at)
      if $kind eq 'punct' && $text eq ')' && $depth == $open->[2] - 1;
    push @inner, $text unless $kind eq 'skip';
  }
  return;
}

# The clauses of one column definition that no PRAGMA reports: the tokens
# behind the column's name, read at the level of the definition itself -- a
# COLLATE inside a CHECK is part of that CHECK. Returns nothing for a clause
# it cannot follow.
sub _column_clauses {
  my ($tokens) = @_;
  my (%checks, $collate, $generated, $nonconstant);

  for my $at (0 .. $#$tokens) {
    my ($kind, $text, $depth) = @{ $tokens->[$at] };
    next unless $kind eq 'word' && $depth == 1;
    my $word = uc $text;

    if ($word eq 'DEFAULT') {
      $nonconstant = 1 if _nonconstant_default($tokens, $at + 1);
    }

    if ($word eq 'CHECK') {
      my ($expr) = _group($tokens, $at + 1);
      return unless defined $expr;
      $checks{$expr} = 1;
    }
    elsif ($word eq 'COLLATE') {
      my ($name) = grep { $_->[0] ne 'skip' } @$tokens[ $at + 1 .. $#$tokens ];
      return unless $name && ($name->[0] eq 'word' || $name->[0] eq 'quoted');
      $collate = lc token_identifier(@$name);
    }
    elsif ($word eq 'AS') {
      my ($expr, $end) = _group($tokens, $at + 1);
      return unless defined $expr;
      my ($next) = grep { $_->[0] ne 'skip' } @$tokens[ $end + 1 .. $#$tokens ];
      my $stored = $next && $next->[0] eq 'word' && uc $next->[1] eq 'STORED';
      $generated = $expr . ($stored ? ' STORED' : ' VIRTUAL');
    }
  }

  return {
    checks      => [ sort keys %checks ],
    collate     => $collate,
    generated   => $generated,
    nonconstant => $nonconstant ? 1 : 0,
  };
}

# Whether the DEFAULT whose value begins at or behind $tokens->[$from] is one
# SQLite refuses in an ADD COLUMN for a table that holds rows (karr k65): any
# parenthesised expression, and CURRENT_TIME, CURRENT_DATE, CURRENT_TIMESTAMP.
# A literal is not -- a number, a string, NULL, TRUE, FALSE, a signed number --
# and neither is such a literal in parentheses, which SQLite takes as constant
# (`DEFAULT (NULL)`). Anything else in the parentheses counts as an expression.
sub _nonconstant_default {
  my ($tokens, $from) = @_;
  my @rest = grep { $_->[0] ne 'skip' } @$tokens[ $from .. $#$tokens ];
  my $first = $rest[0] or return 0;

  return 1 if $first->[0] eq 'word'
    && $first->[1] =~ /\ACURRENT_(?:TIME|DATE|TIMESTAMP)\z/i;
  return 0 unless $first->[0] eq 'punct' && $first->[1] eq '(';

  my ($expr, $end) = _group($tokens, $from);
  return 1 unless defined $expr;    # cannot follow it: treat as an expression
  my $open = $from;
  $open++ while $tokens->[$open][0] eq 'skip';
  my @inner = grep { $_->[0] ne 'skip' } @$tokens[ $open + 1 .. $end - 1 ];
  shift @inner if @inner == 2 && $inner[0][0] eq 'word' && $inner[0][1] =~ /\A[-+]\z/;
  return 1 unless @inner == 1;
  my ($kind, $text) = @{ $inner[0] };
  return 0 if $kind eq 'quoted' && $text =~ /\A'/;
  return 0 if $kind eq 'word'
    && $text =~ /\A(?:NULL|TRUE|FALSE|[0-9][0-9a-z_.]*|\.[0-9][0-9a-z_.]*)\z/i;
  return 1;
}

sub _declarations {
  my ($sql) = @_;

  # CREATE TABLE name ( -- the list starts behind the name.
  my @tokens = sql_tokens($sql);
  my $name_at = create_table_name_index(\@tokens);
  return unless defined $name_at;
  splice @tokens, 0, $name_at + 1;
  shift @tokens while @tokens && $tokens[0][0] eq 'skip';
  my $open = shift @tokens;
  return unless $open && $open->[0] eq 'punct' && $open->[1] eq '(';

  # The items of the parenthesised list, split at its own commas. A token is
  # [ kind, text, depth ]; depth 1 is the item itself, deeper is inside one of
  # its parentheses.
  my (@items, @item);
  my $depth = 1;
  while ($depth && @tokens) {
    my ($kind, $text) = @{ shift @tokens };
    if ($kind eq 'punct') {
      $depth++ if $text eq '(';
      $depth-- if $text eq ')';
      if ($depth == 0 || ($depth == 1 && $text eq ',')) {
        push @items, [@item];
        @item = ();
        next;
      }
    }
    push @item, [ $kind, $text, $depth ];
  }
  return if $depth;

  my (%columns, %constrained, %checks);
  for my $item (@items) {
    my @tokens = @$item;
    shift @tokens while @tokens && $tokens[0][0] eq 'skip';
    return unless @tokens;
    my ($kind, $text) = @{ shift @tokens };

    # None of these five can be a column name unless it is quoted.
    if ($kind eq 'word' && $text =~ /\A(?:CONSTRAINT|PRIMARY|UNIQUE|CHECK|FOREIGN)\z/i) {
      # A table CHECK, on its own or behind CONSTRAINT name.
      my @whole = ([ $kind, $text, 1 ], @tokens);
      for my $at (0 .. $#whole) {
        my ($k, $t, $d) = @{ $whole[$at] };
        next unless $k eq 'word' && $d == 1 && uc $t eq 'CHECK';
        my ($expr) = _group(\@whole, $at + 1);
        return unless defined $expr;
        $checks{$expr} = 1;
      }

      for my $token (@tokens) {
        my ($k, $t, $d) = @$token;
        last if $k eq 'word' && $d == 1 && uc $t eq 'REFERENCES';
        $constrained{ lc token_identifier($k, $t) } = 1 if $k eq 'word' || $k eq 'quoted';
      }
      next;
    }

    my $name = token_identifier($kind, $text);
    return if exists $columns{$name};

    my $definition = join '', map { $_->[0] eq 'skip' ? ' ' : $_->[1] } @tokens;
    $definition =~ s/\A | \z//g;
    my $clauses = _column_clauses(\@tokens) or return;
    $columns{$name} = {
      sql   => $definition,
      keyed => scalar(grep {
        $_->[0] eq 'word' && $_->[2] == 1 && $_->[1] =~ /\A(?:PRIMARY|UNIQUE)\z/i
      } @tokens),
      %$clauses,
    };
  }

  return {
    columns     => \%columns,
    constrained => \%constrained,
    checks      => [ sort keys %checks ],
  };
}

# The fields of a column that changed: changed_column_fields, less a default
# that is the same one spelled in the other way -- see "What counts as a
# changed column". Every place that asks whether or how a column changed asks
# here, so that the op and what it says of itself cannot disagree.
#
# Measured against SQLite 3.51: in a TEXT column a bare integer and the same
# digits in apostrophes store the same text as long as the integer fits into
# 64 bit. Past that it is read as a REAL (9223372036854775808 is stored as
# 9.22337203685478e+18). 18 digits always fit; the 19-digit values that fit
# too are given up for a rule that needs no arithmetic.
my $STRING_AS_INTEGER = qr/\A-?(?:0|[1-9]\d{0,17})\z/;

sub _same_text_default {
  my ($old, $new) = @_;
  return 0 if grep { type_affinity($_->{data_type}) ne 'TEXT' } $old, $new;

  my @defaults = ($old->{default_value}, $new->{default_value});
  return 0 if grep { !defined } @defaults;

  for my $pair ([@defaults], [ reverse @defaults ]) {
    my ($bare, $quoted) = @$pair;
    return 1
      if $bare =~ $STRING_AS_INTEGER && $bare ne '-0' && $quoted eq "'$bare'";
  }
  return 0;
}

sub _changed_fields {
  my ($old, $new, $described) = @_;
  my @changed = changed_column_fields($old, $new);

  # The core leaves a field the target does not state alone. A target that is
  # the introspection of a database deployed from the schema states all of it:
  # a column without a default is a column without one, and the default the
  # live column has is removed (karr k91). A live DEFAULT NULL is no default.
  push @changed, 'default_value'
    if $described && !defined $new->{default_value}
      && defined $old->{default_value} && uc $old->{default_value} ne 'NULL';

  return @changed
    unless (grep { $_ eq 'default_value' } @changed)
      && _same_text_default($old, $new);
  return grep { $_ ne 'default_value' } @changed;
}


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;

  # ($definition, $needs_rebuild) of a column the target adds. Nothing at all
  # when the model has no CREATE TABLE statement for the table: no statement,
  # or that of a view or a virtual table, which neither an ALTER nor a rebuild
  # applies to.
  my %declared;
  my $declaration = sub {
    my ($table, $name) = @_;
    my $sql = $target_tables && ($target_tables->{$table} // {})->{sql};
    return unless defined $sql && $sql =~ /\A\s*CREATE\s+TABLE\b/i;

    my $table_ddl = $declared{$table} //= _declarations($sql) // {};
    my $column    = $table_ddl->{columns}{$name} or return (undef, 1);
    return (
      $column->{sql},
      ($column->{keyed} || $column->{nonconstant}
        || $table_ddl->{constrained}{ lc $name }) ? 1 : 0,
    );
  };

  # The create/change/drop walk over columns nested under retained tables is
  # the generic DBIO::Diff::Op->diff_nested. Only tables present in both models
  # are walked (scope 'both') -- columns of brand-new / dropped tables ride
  # along with the table op. _changed_fields is the per-engine "did this
  # column change" predicate; everything else here is SQLite-shaped ops.
  #
  # is_auto_increment is not SQLite's to express in a WITHOUT ROWID table (it
  # needs the rowid), so the columns of such a table, in either model, are
  # compared without it -- see "What counts as a changed column".
  my %no_autoinc;
  for my $side ([$source_cols, $source_tables], [$target_cols, $target_tables]) {
    my ($cols, $tables) = @$side;
    for my $table (keys %{ $tables || {} }) {
      next unless $tables->{$table}{without_rowid};
      $no_autoinc{ refaddr $_ } = 1 for @{ $cols->{$table} || [] };
    }
  }
  # A target table that has its CREATE TABLE statement is the introspection of
  # a deployed schema and states every column in full, a default included.
  my %described;
  for my $table (keys %{ $target_tables || {} }) {
    my $sql = $target_tables->{$table}{sql};
    next unless defined $sql && $sql =~ /\A\s*CREATE\s+TABLE\b/i;
    $described{ refaddr $_ } = 1 for @{ $target_cols->{$table} || [] };
  }
  my $changed_when = sub {
    my ($old, $new) = @_;
    my $described = $described{ refaddr $new } ? 1 : 0;
    return scalar _changed_fields($old, $new, $described)
      unless $no_autoinc{ refaddr $old } || $no_autoinc{ refaddr $new };
    my %old = %$old; my %new = %$new;
    delete $old{is_auto_increment}; delete $new{is_auto_increment};
    return scalar _changed_fields(\%old, \%new, $described);
  };

  my @ops = $class->diff_nested($source_cols, $target_cols,
    index_by      => 'column_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => $changed_when,
    on_new => sub {
      my ($table, $name, $new) = @_;
      my ($definition, $needs_rebuild) = $declaration->($table, $name);
      $class->new(
        action        => 'add',
        table_name    => $table,
        column_name   => $name,
        new_info      => $new,
        definition    => $definition,
        needs_rebuild => $needs_rebuild,
      );
    },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      $class->new(
        action           => 'alter',
        table_name       => $table,
        column_name      => $name,
        old_info         => $old,
        new_info         => $new,
        target_described => $described{ refaddr $new } ? 1 : 0,
      );
    },
    on_gone => sub {
      my ($table, $name, $old) = @_;
      $class->new(
        action      => 'drop',
        table_name  => $table,
        column_name => $name,
        old_info    => $old,
      );
    },
  );

  # diff_nested walks the names sorted; put each table's add ops into the
  # target's column order. The tables come sorted and stay so, which leaves
  # every table's ops in the places they had.
  my %position;
  for my $table (keys %{ $target_cols // {} }) {
    my $columns = $target_cols->{$table};
    next unless ref $columns eq 'ARRAY';
    $position{$table}{ $columns->[$_]{column_name} } = $_ for 0 .. $#$columns;
  }
  my @adds = grep { $ops[$_]->action eq 'add' } 0 .. $#ops;
  @ops[@adds] = sort {
    $a->table_name cmp $b->table_name
      or ($position{ $a->table_name }{ $a->column_name } // 0)
        <=> ($position{ $b->table_name }{ $b->column_name } // 0)
  } @ops[@adds];

  return @ops;
}


# One changed field of an alter op, as the refusal names it. The fields are
# named in this order, whichever one the comparison found first.
my @FIELDS      = qw(data_type not_null default_value size);
my %FIELD_LABEL = (
  data_type     => 'type',
  not_null      => 'NOT NULL',
  default_value => 'default',
  size          => 'size',
);

sub _field_change {
  my ($field, $old, $new) = @_;
  my ($from, $to) = map {
    my $value = $_->{$field};
    $field eq 'not_null' ? ($value ? 'yes' : 'no')
      : !defined $value      ? 'none'
      : ref $value eq 'ARRAY' ? join(',', @$value)
      :                         $value;
  } $old, $new;
  return sprintf '%s %s -> %s', $FIELD_LABEL{$field} // $field, $from, $to;
}


sub changes {
  my ($self) = @_;
  my ($old, $new) = ($self->old_info, $self->new_info);
  my %changed = map { $_ => 1 }
    _changed_fields($old, $new, $self->target_described);
  return join ', ',
    map { _field_change($_, $old, $new) } grep { $changed{$_} } @FIELDS;
}

sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'add') {
    if ($self->needs_rebuild) {
      Carp::croak(sprintf
        'Cannot add column %s.%s by ALTER TABLE: ADD COLUMN cannot carry its '
        . 'declaration (UNIQUE, PRIMARY KEY, a table constraint naming the '
        . 'column or a non-constant DEFAULT), table %s has to be rebuilt from its CREATE TABLE statement',
        $self->table_name, $self->column_name, $self->table_name);
    }

    my $sql = sprintf 'ALTER TABLE %s ADD COLUMN %s',
      quote_identifier($self->table_name),
      quote_identifier($self->column_name);

    # The column as the target declares it (karr k64).
    if (defined(my $definition = $self->definition)) {
      $sql .= " $definition" if length $definition;
      return "$sql;";
    }

    my $info = $self->new_info;
    $sql .= ' ' . type_with_size($info->{data_type} // 'TEXT', $info->{size});
    $sql .= ' NOT NULL' if $info->{not_null};
    if (defined $info->{default_value}) {
      $sql .= ' DEFAULT ' . default_value_sql($info->{default_value});
    }
    return "$sql;";
  }
  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;',
      quote_identifier($self->table_name),
      quote_identifier($self->column_name);
  }
  if ($self->action eq 'alter') {
    Carp::croak(sprintf
      'Cannot change column %s.%s (%s): SQLite has no ALTER COLUMN, and the '
      . 'target model holds no CREATE TABLE statement to rebuild table %s from',
      $self->table_name, $self->column_name, $self->changes,
      $self->table_name);
  }
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'add' ? '+' : $self->action eq 'drop' ? '-' : '~';
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s', $prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::Column - Diff operations for SQLite columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a column-level diff operation in SQLite. Only ADD COLUMN is
supported as a true ALTER -- SQLite has very limited C<ALTER TABLE>:
since 3.25 it can rename columns and since 3.35 it can drop columns,
but type changes still require the create-new-table-and-copy dance.

For now this module emits:

=over 4

=item * C<ALTER TABLE ... ADD COLUMN ...> for added columns, carrying the
        column as the target declares it -- see L</Added columns>

=item * C<ALTER TABLE ... DROP COLUMN ...> for dropped columns (3.35+)

=item * Nothing for a changed type, nullability or default -- a true
        in-place ALTER is impossible. When the target table's original
        C<CREATE> statement is known, L<DBIO::SQLite::Diff> hoists such a
        column into a whole-table L<DBIO::SQLite::Diff::Rebuild> instead, and
        the op is never rendered. Where no captured DDL is available (the
        compiled-model path) there is nothing to rebuild the table from, and
        L</as_sql> throws -- see L</Changes that are refused>.

=back

Brand-new tables come with their columns, in the C<CREATE> statement
L<DBIO::SQLite::Diff::Table> emits -- this module only sees columns of tables
that exist in both source and target. L<DBIO::SQLite::Diff> hands it the
B<plain> tables only: a view or a virtual table never gets a column op
(L<DBIO::SQLite::Diff/What a name is>).

A column's C<CHECK>, C<COLLATE> and generated expression are not among the
fields compared here. L<DBIO::SQLite::Diff> compares them, for a column both
tables have, out of the two C<CREATE TABLE> statements, and rebuilds the table
when they differ (L<DBIO::SQLite::Diff/When a table is rebuilt>). The reader of
those statements is the one this module reads an added column's declaration
with.

=head2 What counts as a changed column

A column has changed when its type, its C<NOT NULL>, its default or its size
differs between the two models. That is
L<DBIO::Diff::Compare/changed_column_fields>, which compares a default as the
text C<PRAGMA table_xinfo> reports, with one exception made here.

B<A default that is an integer, in a column that stores text, is the same
default bare and in apostrophes.> C<code VARCHAR(10) DEFAULT 10> and
C<code VARCHAR(10) DEFAULT '10'> give every new row the text C<10>: the column
makes that text of the number. L<DBIO::SQLite::DDL> wrote the first form until
it began to write the default of such a column as a string literal
(L<DBIO::SQLite::Util/default_literal_sql>), so a database deployed before
that holds the first and the schema now declares the second. Read as a change,
every table with such a column would be rebuilt by the next upgrade, to arrive
at a table that behaves as it did.

The two are taken for one default when all of this holds, whichever of the two
models has which spelling:

=over 4

=item * the column has TEXT affinity in both models
        (L<DBIO::SQLite::Util/type_affinity> of its C<data_type>);

=item * one default is an integer as SQLite itself writes one -- digits, a
        minus sign if negative, no leading zero, no plus sign, not C<-0> -- of
        at most 18 digits;

=item * the other is exactly those characters between two apostrophes.

=back

Nothing else is. C<DEFAULT 007> gives the text C<7> and C<DEFAULT '007'> the
text C<007>; C<1.50> arrives as C<1.5>; an integer past 64 bit is read as a
floating point number, and C<9223372036854775808> is stored as
C<9.22337203685478e+18>. Those are two defaults each, and the rebuild that
follows is what brings the declared one into an older database. Two cases
store alike and are reported as changed all the same, for the sake of a rule
that fits into one line: a decimal that is already in SQLite's own spelling
(C<1.5>), and an integer of 19 digits that still fits into 64 bit. In a column
without TEXT affinity the rule does not apply at all.

B<A default the target does not give is a default to remove,> where the target
table has its C<CREATE TABLE> statement -- the introspection of a deployed
schema, which states every column in full. The core leaves a field the target
leaves undefined alone; here a column without a default is a column without
one, and a live default (other than C<NULL>, which is none) is a change, the
table is rebuilt and the new rows get no default. A target without
the statement (L<DBIO::SQLite::Diff/target_from_compiled>) prescribes no such
thing, and the live default stays.

B<C<is_auto_increment> is compared only where SQLite can express it.> It is
the C<INTEGER PRIMARY KEY> of a table with a rowid; the C<id> of a C<WITHOUT
ROWID> table is no alias of anything and L<DBIO::SQLite::Introspect::Columns>
does not report it. In a table that either model marks C<without_rowid> a
difference in C<is_auto_increment> is therefore not a change, so a target that
declares the key as auto increment does not rebuild a C<WITHOUT ROWID> table
that only the database has. In a table with a rowid it is compared like the
rest.

=head2 Added columns

A column is more than the fields the model holds for it. C<PRAGMA table_xinfo>
reports a type, C<NOT NULL> and a default; a C<REFERENCES> clause with its
C<ON DELETE>, a C<CHECK>, a C<COLLATE> and a generated column's expression are
not among them, and C<UNIQUE> shows up only as an automatic index. An
C<ADD COLUMN> written from those fields adds a column without any of it, and
the next diff sees nothing wrong, because it compares the same fields.

So where the target model has the table's C<CREATE TABLE> statement -- the
C<sql> of C<sqlite_master>, which every introspected model has -- the column's
declaration is read out of that statement and the C<ADD COLUMN> carries it as
written. Comments are left out and whitespace between the words becomes one
space; nothing else is changed.

C<ALTER TABLE ... ADD COLUMN> cannot say everything a C<CREATE TABLE> can. An
C<add> op has L</needs_rebuild> set when it is one of these, and
L<DBIO::SQLite::Diff> then rebuilds the table from the target statement
instead (ADR 0003):

=over 4

=item * the declaration carries C<UNIQUE> or C<PRIMARY KEY>, which SQLite
        refuses in an C<ADD COLUMN> (C<Cannot add a UNIQUE column>);

=item * a table constraint names the column -- C<PRIMARY KEY (...)>,
        C<UNIQUE (...)>, C<CHECK (...)>, or the column list of a
        C<FOREIGN KEY (...)>. SQLite has no statement that adds a table
        constraint, and this is the form L<DBIO::SQLite::DDL> writes every
        foreign key and every unique constraint in. The columns a
        C<FOREIGN KEY> points I<at> belong to the other table and do not
        count;

=item * the declaration carries a C<DEFAULT> that is not a constant: any
        parenthesised expression (C<DEFAULT (datetime('now'))>) and
        C<CURRENT_TIME>, C<CURRENT_DATE>, C<CURRENT_TIMESTAMP>. SQLite takes
        such an C<ADD COLUMN> for an empty table and refuses it for one that
        holds rows (C<Cannot add a column with non-constant default>), and a
        diff of two models does not know which table it has. The rebuild
        evaluates the default for every copied row. A literal --
        number, string, C<NULL>, C<TRUE>, C<FALSE>, a signed number -- is not
        such a default, nor is one of them alone in parentheses
        (C<DEFAULT (NULL)>); those stay C<ADD COLUMN>. The price is that an
        empty table is rebuilt too;

=item * the declaration cannot be found in the statement. The form written
        from the fields is the one known to lose things, so it is not what a
        statement this module fails to read falls back to.

=back

The names in a table constraint are matched as words, not understood: a
C<CHECK> that holds the column's name in a string literal rebuilds the table
too. That direction is the harmless one.

What SQLite refuses only for a table that B<holds rows> and a rebuild would not
help is not in that list: a C<NOT NULL> column without a default (the copy
into the new table fails the same way), a C<REFERENCES> column with a default
other than C<NULL> while foreign keys are enforced, and a C<STORED> generated
column. Those are emitted as C<ADD COLUMN>, apply to an empty table and fail at
SQLite for a populated one.

A model without the statement -- L<DBIO::SQLite::Diff/target_from_compiled>,
or one built by hand -- has only the fields, and its added columns are
written from them: type, C<NOT NULL>, C<DEFAULT>. That is all such a model
knows of a column, and it is not the column L<DBIO::SQLite::DDL> declares for
the same result class.

=head2 Changes that are refused

A change this module has no statement for is refused: L</as_sql> throws, with
a message that names the table, the column, what changed and why it cannot be
done. It does not answer with an SQL comment. A comment is either run -- core
splits a script at every semicolon, one inside a comment included -- or
dropped, and then a diff that reports changes applies none and says nothing.

Two ops are refused:

=over 4

=item * an C<alter> -- a changed type, C<NOT NULL> or default. Inside
        L<DBIO::SQLite::Diff> that is the case of a target model without the
        table's C<CREATE TABLE> statement
        (L<DBIO::SQLite::Diff/target_from_compiled>, a model built by hand):
        with the statement the table is rebuilt and the op is not rendered;

=item * an C<add> with L</needs_rebuild> set. L<DBIO::SQLite::Diff> always
        rebuilds for these, so only a caller that renders the op on its own
        meets the refusal.

=back

L<DBIO::SQLite::Diff>'s C<as_sql> renders every op, so one refused op refuses
the whole diff, and L<DBIO::SQLite::Deploy/apply> renders the diff before it
runs the first statement: nothing has been applied when it throws.
L</summary> and C<has_changes> are not affected -- what the diff contains can
still be printed.

=head2 Changes that lose data

A changed column is I<lossy> when the rebuild that applies it may alter or
lose a stored value (L<DBIO::Diff::Base/destructive_operations>): L</lossy>
answers it through L<DBIO::Diff::Compare/column_change_lossy>, and a lossy
change runs only with C<< allow_destructive => 1 >>
(L<DBIO::Deploy::Base/apply>).

A change of the type name is lossless in SQLite only for the pairs of
L</lossless_type_pairs>, which are the pairs of names with the B<same type
affinity> (L<DBIO::SQLite::Util/type_affinity>). SQLite stores the value, not
the column's type; the affinity is the one thing a column does to a value on
the way in (L<https://www.sqlite.org/datatype3.html>, section 3). A table
rebuild copies the rows with C<INSERT ... SELECT>, so every value passes the
affinity of the new column once more, and for two names of one affinity that
is the conversion it passed when it was stored: the value and its storage
class come back as they were. The list holds these names, per affinity:

=over 4

=item * C<INTEGER>: C<integer>, C<int>, C<bigint>, C<smallint>, C<tinyint>,
        C<mediumint>, C<int2>, C<int8>;

=item * C<TEXT>: C<text>, C<varchar>, C<char>, C<character>, C<nchar>,
        C<nvarchar>, C<clob>;

=item * C<REAL>: C<real>, C<double>, C<double precision>, C<float>;

=item * C<NUMERIC>: C<numeric>, C<decimal>, C<boolean>, C<date>, C<datetime>;

=item * C<BLOB>: C<blob>, and the empty type.

=back

Every other pair is lossy, a change of affinity first: C<INTEGER> to C<REAL>
turns a large integer into a float that no longer holds it, any number to
C<TEXT> into its text, C<TEXT> to C<INTEGER> or C<NUMERIC> into a number
wherever the text reads as one, and C<REAL> to C<INTEGER> or C<NUMERIC> may
turn C<1.0> into C<1>. A type name the list does not know is lossy as well:
in doubt the change is not released. SQLite does not enforce a declared size,
so a smaller size loses no value there, but the size is judged as
L<DBIO::Diff::Compare/column_change_lossy> does for any driver, and a
shrinking size of a type is lossy.

=head1 ATTRIBUTES

=head2 definition

For an C<add> op: what follows the column's name in the target table's
C<CREATE TABLE> statement -- type and constraints, as declared. Undefined
when the target model has no such statement, or the column is not in it.

=head2 needs_rebuild

True for an C<add> op that C<ALTER TABLE ... ADD COLUMN> cannot express; see
L</Added columns>. L<DBIO::SQLite::Diff> turns the table into a
L<DBIO::SQLite::Diff::Rebuild> then. Rendered on its own, such an op is
refused by L</as_sql>.

=head1 METHODS

=head2 lossless_type_pairs

    my $pairs = DBIO::SQLite::Diff::Column->lossless_type_pairs;
    $pairs->{'varchar->text'};    # 1

The hash reference of the pairs of type names a change of which loses no value,
keys C<< old->new >> in lower case, as L<DBIO::Diff::Compare/column_change_lossy>
takes it. See L</Changes that lose data> for what is in it and why. A copy:
changing it changes nothing.

=head2 lossy

    my $bool = $op->lossy;

True for an C<alter> op that may alter or lose a stored value, by
L<DBIO::Diff::Compare/column_change_lossy> with L</lossless_type_pairs>. False
for any other action: an added column loses nothing, and a dropped one is
destructive by its action. The operation method of
L<DBIO::Diff::Base/destructive_operations>.

=head2 diff

    my @ops = DBIO::SQLite::Diff::Column->diff(
        $source_columns, $target_columns,
        $source_tables,  $target_tables,
    );

Compares column lists for tables that exist in both source and target. Which
columns come out as changed is described under
L</What counts as a changed column>.

The target tables are also where an C<add> op gets its L</definition> and its
L</needs_rebuild> from: the C<sql> of the table entry, when that is a
C<CREATE TABLE> statement.

The C<add> ops of a table come in the order the target declares the columns,
not sorted by name. C<ADD COLUMN> appends, so that is the order the columns end
up in, and a C<CHECK> or a generated column may name a column declared before
it, which has to exist by then.

=head2 as_sql

Returns the C<ALTER TABLE> statement for this operation, and throws for a
change no C<ALTER TABLE> expresses (L</Changes that are refused>):

    Cannot change column t.c (type INTEGER -> TEXT, NOT NULL no -> yes):
    SQLite has no ALTER COLUMN, and the target model holds no CREATE TABLE
    statement to rebuild table t from

The message is one line; the parentheses hold each changed field with its old
and its new value -- C<type>, C<NOT NULL>, C<default>, C<size>.

An added column with a L</definition> is that definition behind
C<ALTER TABLE ... ADD COLUMN name>, the table and the column quoted
(L<DBIO::SQLite::Util/quote_identifier>) and the definition as the target
declares it:

    ALTER TABLE "item" ADD COLUMN "note" VARCHAR(40) DEFAULT 'none';

One with L</needs_rebuild> set throws,
like an C<alter>: L<DBIO::SQLite::Diff> never renders it, it emits the
rebuild, and whoever renders the op alone gets no statement that would add
half the column.

Without a definition -- a model that has no statement, see L</Added columns>
-- the column is written from its fields. Its C<DEFAULT> is rendered by
L<DBIO::SQLite::Util/default_value_sql>, which puts an expression default back
into the parentheses SQLite's grammar requires.

Either way the statement is valid; that does not make SQLite accept it for
every table. Written from the fields, without a statement, a default that is
not a constant -- a function call, C<1+2>, C<'a' || 'b'>, and C<CURRENT_TIMESTAMP>
and its siblings too -- is refused for a table that holds rows (C<Cannot add a
column with non-constant default>) and accepted for an empty one. With a
statement the table is rebuilt instead (L</Added columns>).

=head2 changes

    my $text = $op->changes;    # 'type INTEGER -> TEXT, NOT NULL no -> yes'

For an C<alter> op: each field that changed with its old and its new value,
as the refusal of L</as_sql> names them. L<DBIO::SQLite::Diff> gives it to the
L<DBIO::SQLite::Diff::Rebuild> that takes the op's place, as the reason of the
rebuild.

=head2 summary

One line naming the op -- C<+column>, C<-column> or C<~column>, table and
column. It never throws, for an op L</as_sql> refuses either.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
