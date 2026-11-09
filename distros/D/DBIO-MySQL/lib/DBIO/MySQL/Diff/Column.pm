package DBIO::MySQL::Diff::Column;
# ABSTRACT: Diff operations for MySQL/MariaDB columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_fields column_change_lossy);
use DBIO::MySQL::Identifier qw(quote_ident quote_table_in);
use DBIO::MySQL::DefaultValue qw(default_sql on_update_sql);
use DBIO::MySQL::Diff::View ();

__PACKAGE__->mk_diff_accessors(qw(
  table_name column_name old_info new_info table_collation database
));



sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;

  # a view is no table, and its columns are not diffed (karr k79)
  ($source_tables, $source_cols) = DBIO::MySQL::Diff::View::without_views($source_tables, $source_cols);
  ($target_tables, $target_cols) = DBIO::MySQL::Diff::View::without_views($target_tables, $target_cols);

  # A table whose collation changes is converted (DBIO::MySQL::Diff::Table, karr
  # k109), which gives every text column the character set and collation of the
  # target: they are not compared, a MODIFY COLUMN could not even write them.
  $source_cols = _converted_columns($source_cols, $target_cols, $source_tables, $target_tables);

  my @ops = $class->diff_nested(
    $source_cols, $target_cols,
    index_by      => 'column_name',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => \&_mysql_column_changed,
    on_new => sub {
      my ($table_name, $column_name, $new_info) = @_;
      $class->new(action => 'add', table_name => $table_name,
        column_name => $column_name, new_info => $new_info,
        table_collation => ($target_tables->{$table_name} // {})->{table_collation});
    },
    on_changed => sub {
      my ($table_name, $column_name, $old_info, $new_info) = @_;
      $class->new(action => 'modify', table_name => $table_name,
        column_name => $column_name, old_info => $old_info, new_info => $new_info,
        table_collation => ($target_tables->{$table_name} // {})->{table_collation});
    },
    on_gone => sub {
      my ($table_name, $column_name, $old_info) = @_;
      $class->new(action => 'drop', table_name => $table_name,
        column_name => $column_name, old_info => $old_info);
    },
  );

  # diff_nested walks the columns by name. The columns a table gains are added
  # in the order the target declares them, so a table the diff extends has
  # them in the order a fresh one has (karr k92): the places the adds of a
  # table hold are filled again with them in the order of the target.
  my %adds;
  for my $op (grep { $_->action eq 'add' } @ops) {
    push @{ $adds{ $op->table_name } }, $op;
  }
  for my $table (keys %adds) {
    my $i = 0;
    my %pos = map { ($_->{column_name} => $i++) } @{ $target_cols->{$table} // [] };
    $adds{$table} = [ sort { $pos{ $a->column_name } <=> $pos{ $b->column_name } } @{ $adds{$table} } ];
  }
  return map { $_->action eq 'add' ? shift @{ $adds{ $_->table_name } } : $_ } @ops;
}

# The source columns of the tables whose collation changes, with the character
# set and collation the conversion gives them: those of the target table. A
# column with a collation of its own in the target is modified after it
# (collation_sql, karr k111).
sub _converted_columns {
  my ($source_cols, $target_cols, $source_tables, $target_tables) = @_;
  my %out = %{ $source_cols // {} };
  for my $table (keys %out) {
    my ($old, $new) = ($source_tables->{$table}, $target_tables->{$table});
    next unless $old && $new && defined $old->{table_collation} && defined $new->{table_collation};
    next if lc $old->{table_collation} eq lc $new->{table_collation};
    my %target = map { $_->{column_name} => $_ } @{ $target_cols->{$table} // [] };
    my ($charset) = $new->{table_collation} =~ /\A([^_]+)_/;
    $out{$table} = [ map {
      my $t = $target{ $_->{column_name} };
      ($t && defined $_->{character_set} && defined $t->{character_set} && defined $charset)
        ? { %$_, character_set => $charset, collation => $new->{table_collation} }
        : $_
    } @{ $out{$table} } ];
  }
  return \%out;
}

# MySQL-specific field spec. Compares type/character-set/precision as
# scalar strings, not_null/default_value/comment as the canonical model
# does. desired_state => 1 means "if the target left it undef, treat as
# don't-care" (we do not know what the live DB will assign for charset
# on a portable text column, see Diff.pm ESCALATION NOTE).
sub _mysql_column_changed {
  my ($old, $new) = @_;
  my @changed = changed_fields($old, $new,
    type    => ['data_type'],
    scalar  => [qw(default_value character_set collation comment)],
    bool    => ['not_null'],
    dim     => [qw(numeric_precision numeric_scale datetime_precision)],
    array   => ['values'],
    desired_state => 1,
  );

  # column_type carries the parameterised type (char(32), decimal(10,2)) and is
  # the real width/precision discriminator, so it is compared here rather than as
  # a plain scalar: MySQL 8.0.17+ drops the *display width* from integer types
  # (bigint(20) -> bigint) while MariaDB and MySQL < 8.0.17 keep it. Normalising
  # the integer display width away on BOTH sides keeps that server-version
  # difference from surfacing as a phantom MODIFY. Desired-state contract: only
  # compare when the target ($new) prescribes a column_type.
  if (defined $new->{column_type}
        && _norm_int_display_width($old->{column_type})
        ne _norm_int_display_width($new->{column_type})) {
    push @changed, 'column_type';
  }

  # A target that says whether its default is an expression (the introspection
  # does for every column, the temporary database of an upgrade among them)
  # describes the whole column, and there default_value undef means "no
  # default": the one the live column has is removed (karr k95). A target
  # without that key (target_from_compiled) does not prescribe "none", and the
  # live default is left alone, as changed_fields does for every undef.
  push @changed, 'default_value'
    if !defined $new->{default_value} && defined $new->{default_is_expression}
      && defined $old->{default_value};

  # A default that is an expression on one side and a literal on the other is a
  # change even when the text is the same (karr k78); asked only when the target
  # prescribes a default, like default_value itself.
  push @changed, 'default_is_expression'
    if defined $new->{default_value} && defined $old->{default_value}
      && ($old->{default_is_expression} ? 1 : 0) != ($new->{default_is_expression} ? 1 : 0);

  # ON UPDATE (karr k108) is part of the column the introspection describes, so a
  # target that has the key says "none" with undef and the live one is removed.
  # A target without the key (target_from_compiled) does not prescribe it.
  push @changed, 'on_update'
    if exists $new->{on_update}
      && uc($old->{on_update} // '') ne uc($new->{on_update} // '');

  # AUTO_INCREMENT is compared outright, not under the desired-state contract:
  # both models carry it as 0 or 1 (introspection, target_from_compiled), and
  # a column that gains or loses it is a change (karr k93).
  push @changed, 'is_auto_increment'
    if ($old->{is_auto_increment} ? 1 : 0) != ($new->{is_auto_increment} ? 1 : 0);

  return scalar @changed;
}

# Strip the parenthesised display width from integer-family column types
# (int / integer / tinyint / smallint / mediumint / bigint), e.g.
# 'bigint(20)' -> 'bigint', 'int(10) unsigned' -> 'int unsigned'. tinyint(1) is
# preserved because MySQL keeps that width to signal BOOLEAN. decimal / numeric
# / char / varchar widths are NOT stripped -- there the parenthesised value is
# semantic, not a display width.
sub _norm_int_display_width {
  my ($ct) = @_;
  return '' unless defined $ct;
  my $s = lc $ct;
  $s =~ s/\s+/ /g;
  $s =~ s/^\s+|\s+$//g;
  $s =~ s/\btinyint\((?!1\))\d+\)/tinyint/g;
  $s =~ s/\b(bigint|smallint|mediumint|integer|int)\(\d+\)/$1/g;
  return $s;
}


our %LOSSLESS_PAIRS;
{
  my @ladders = (
    [qw(tinyint smallint mediumint int bigint)],
    [qw(tinytext text mediumtext longtext)],
    [qw(tinyblob blob mediumblob longblob)],
  );
  for my $ladder (@ladders) {
    for my $from (0 .. $#$ladder - 1) {
      $LOSSLESS_PAIRS{"$ladder->[$from]->$ladder->[$_]"} = 1 for $from + 1 .. $#$ladder;
    }
  }
  $LOSSLESS_PAIRS{'char->varchar'} = 1;
  for my $from (qw(char varchar)) {
    $LOSSLESS_PAIRS{"$from->$_"} = 1 for qw(text mediumtext longtext);
  }
  $LOSSLESS_PAIRS{'binary->varbinary'} = 1;
  $LOSSLESS_PAIRS{"varbinary->$_"} = 1 for qw(blob mediumblob longblob);
  $LOSSLESS_PAIRS{'date->datetime'} = 1;
}

# the aliases the server reports one name for
my %ALIAS = (integer => 'int', numeric => 'decimal', bool => 'tinyint', boolean => 'tinyint');

# types whose size is the length or the fractional seconds in the parentheses
my %SIZED = map { $_ => 1 } qw(char varchar binary varbinary bit datetime timestamp time);


sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'modify';
  my ($old, $new) = ($self->old_info // {}, $self->new_info // {});

  my ($ot, $nt) = map { _base_type($_->{data_type}) } $old, $new;
  $nt = $ot unless length $nt;

  my $ctype = defined $new->{column_type} ? lc $new->{column_type} : lc($old->{column_type} // '');
  my $otype = lc($old->{column_type} // '');
  return 1 if ($otype =~ /\bunsigned\b/ ? 1 : 0) != ($ctype =~ /\bunsigned\b/ ? 1 : 0);

  return 1 if defined $new->{character_set} && defined $old->{character_set}
    && lc $new->{character_set} ne lc $old->{character_set};

  if ($nt eq 'enum' || $nt eq 'set') {
    return 1 unless $ot eq $nt;
    my @was = @{ $old->{values} // [] };
    my @now = @{ $new->{values} // $old->{values} // [] };
    return 1 if @now < @was || grep { $was[$_] ne $now[$_] } 0 .. $#was;
    return 0;
  }

  # a type without a size of its own: another parameterised string is a change
  # of the type itself (float(7,3) for float)
  return 1 if $ot eq $nt && !$SIZED{$nt} && $nt !~ /\A(?:tinyint|smallint|mediumint|int|bigint|decimal)\z/
    && defined $new->{column_type} && $otype ne $ctype;

  return column_change_lossy(
    _sized($old, $ot), _sized({ column_type => $new->{column_type} // $old->{column_type} }, $nt),
    \%LOSSLESS_PAIRS,
  ) ? 1 : 0;
}

sub _base_type {
  my ($t) = @_;
  $t = lc($t // '');
  $t =~ s/\s.*\z//s;
  return $ALIAS{$t} // $t;
}

# The info as column_change_lossy reads it: data_type and a size that means
# something. Integers carry none (their width is for display).
sub _sized {
  my ($info, $type) = @_;
  my $ct = $info->{column_type} // '';
  my $size;
  if ($type eq 'decimal') {
    my ($p, $s) = $ct =~ /\(\s*(\d+)\s*(?:,\s*(\d+))?\s*\)/ ? ($1, $2 // 0) : (10, 0);
    $size = [ $p, $s ];
  }
  elsif ($SIZED{$type}) {
    ($size) = $ct =~ /\(\s*(\d+)/;
    $size //= 0 if $type =~ /\A(?:datetime|timestamp|time)\z/;
    $size //= 1 if $type eq 'bit' || $type eq 'char' || $type eq 'binary';
  }
  return { data_type => $type, (defined $size ? (size => $size) : ()) };
}


sub collation_sql {
  my ($info, $table_collation) = @_;
  my ($charset, $collation) = map { defined $_ && length $_ ? lc $_ : undef } @{$info}{qw(character_set collation)};
  return '' unless defined $charset || defined $collation;

  if (defined $table_collation) {
    my $default = lc $table_collation;
    my ($default_charset) = $default =~ /\A([^_]+)_/;
    return '' if defined $collation ? $collation eq $default
               : (defined $default_charset && $charset eq $default_charset);
  }

  return (defined $charset ? " CHARACTER SET $charset" : '')
       . (defined $collation ? " COLLATE $collation" : '');
}


sub as_sql {
  my ($self) = @_;
  my $tbl = quote_table_in($self->database, $self->table_name);
  my $col = quote_ident($self->column_name);

  if ($self->action eq 'add') {
    return sprintf 'ALTER TABLE %s %s;', $tbl, $self->add_clause;
  }
  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;', $tbl, $col;
  }
  if ($self->action eq 'modify') {
    my $info = $self->new_info;
    my $type = $info->{column_type} || $info->{data_type} || 'text';
    my $sql  = sprintf 'ALTER TABLE %s MODIFY COLUMN %s %s', $tbl, $col, $type;
    $sql .= collation_sql($info, $self->table_collation);
    $sql .= ' NOT NULL' if $info->{not_null};
    $sql .= ' AUTO_INCREMENT' if $info->{is_auto_increment};
    if (defined $info->{default_value}) {
      $sql .= " DEFAULT " . default_sql($info->{default_value}, $info->{default_is_expression});
    }
    $sql .= on_update_sql($info->{on_update});
    return "$sql;";
  }
}


sub add_clause {
  my ($self, $auto_increment) = @_;
  my $info = $self->new_info;
  my $type = $info->{column_type} || $info->{data_type} || 'text';
  my $sql  = sprintf 'ADD COLUMN %s %s', quote_ident($self->column_name), $type;
  $sql .= collation_sql($info, $self->table_collation);
  $sql .= ' NOT NULL' if $info->{not_null};
  $sql .= ' AUTO_INCREMENT' if $auto_increment && $info->{is_auto_increment};
  $sql .= " DEFAULT " . default_sql($info->{default_value}, $info->{default_is_expression})
    if defined $info->{default_value};
  $sql .= on_update_sql($info->{on_update});
  return $sql;
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'add' ? '+'
             : $self->action eq 'drop' ? '-' : '~';
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s',
    $prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff::Column - Diff operations for MySQL/MariaDB columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a column-level diff operation in MySQL/MariaDB. Unlike
SQLite, MySQL has full C<ALTER TABLE> support so all of C<ADD COLUMN>,
C<DROP COLUMN>, and C<MODIFY COLUMN> are emitted directly.

Brand-new tables get their columns inline via L<DBIO::MySQL::Diff::Table>
-- this module only sees columns of tables that exist in both source
and target.

=head1 ATTRIBUTES

=head2 lossy_pairs

    my %pairs = %DBIO::MySQL::Diff::Column::LOSSLESS_PAIRS;

The changes of C<data_type> that MySQL and MariaDB carry out without loss, as
the C<< old->new >> keys L<DBIO::Diff::Compare/column_change_lossy> reads: the
integer types to a wider one (C<tinyint> E<lt> C<smallint> E<lt> C<mediumint>
E<lt> C<int> E<lt> C<bigint>), the text types and the blob types to a larger
one, C<char> to C<varchar>, C<char> and C<varchar> to C<text>, C<mediumtext>
and C<longtext> (C<tinytext> holds 255 bytes, fewer than a C<varchar(255)>),
C<binary> to C<varbinary>, C<varbinary> to the blobs from C<blob> up, and
C<date> to C<datetime>. Every other pair of types is lossy, in doubt it is:
C<float> to C<double> alters the decimal reading of a value, C<datetime> to
C<timestamp> narrows the range, a number to a string rewrites it.

=head1 METHODS

=head2 diff

    my @ops = DBIO::MySQL::Diff::Column->diff(
        $source_cols, $target_cols,
        $source_tables, $target_tables,
    );

Compares column lists for tables that exist in both source and target. Detects
added columns, dropped columns, and modified columns (data type, C<NOT NULL>,
default value or C<ON UPDATE> changes). Returns a list of
C<DBIO::MySQL::Diff::Column> objects. C<ON UPDATE> (C<on_update> in the model)
is compared when the target carries the key, as the introspection does for
every column, and C<MODIFY COLUMN>, C<ADD COLUMN> and the C<CREATE TABLE> of
L<DBIO::MySQL::Diff::Table> write it; a column whose target has none loses it,
and a target from C<target_from_compiled>, which has no such key, leaves it
alone. A column that gains or loses C<AUTO_INCREMENT> is modified too, and a
C<MODIFY COLUMN> of a column that is C<AUTO_INCREMENT> in the target keeps the
attribute. A column that is C<AUTO_INCREMENT> without being the primary key
has to have a key; the statement that takes the attribute from it stands
before the C<DROP INDEX> of that key, see L<DBIO::MySQL::Diff>. The columns a
table gains are added in the order the target declares them, not in the order
of their names.

The MySQL column shape carries extras beyond the canonical model
(C<column_type>, C<character_set>, C<collation>, C<numeric_precision>,
C<numeric_scale>, C<datetime_precision>, C<values>, C<comment>) so we
use L<DBIO::Diff::Compare/changed_fields> with a MySQL-specific field
spec instead of the canonical L<changed_column_fields|DBIO::Diff::Compare/changed_column_fields>.

A column with a character set or collation of its own, off the default of its
table, has them written by C<MODIFY COLUMN> and C<ADD COLUMN>
(L</collation_sql>); one on the default is written without.

=head2 lossy

True for a C<modify> that can alter or lose stored values, so that
L<DBIO::Deploy::Base/apply> runs it only with C<allow_destructive>.
The answer is L<DBIO::Diff::Compare/column_change_lossy> over the types and
sizes of the two columns, with the pairs of L</lossy_pairs>, and four things the
generic comparison does not see:

=over 4

=item * C<unsigned> gained or lost -- negative values go, or large ones do not fit;

=item * another C<character_set> -- text of one may not be representable in the other;

=item * an C<enum> or C<set> whose values are not the old ones with more behind them;

=item * a type without a size of its own (C<float>, C<double>, C<json>, ...)
whose C<column_type> is another string.

=back

A change of C<NOT NULL>, the default, the comment, C<ON UPDATE>, the collation
within one character set and C<AUTO_INCREMENT> keeps every value and is not
lossy (C<NOT NULL> over a C<NULL> is refused by
L<DBIO::MySQL::Deploy/_refuse_unfillable>). The integer display width
(C<int(11)>) is no size. Other actions are not lossy.

=head2 collation_sql

    my $sql = DBIO::MySQL::Diff::Column::collation_sql($column_info, $table_collation);

The C<CHARACTER SET> and C<COLLATE> of a column, with a leading blank, where
they differ from the default of its table, and the empty string where they do
not. A column on the default is written without, as the server gives it the
default of the table; one off it needs them in every C<MODIFY COLUMN>, C<ADD
COLUMN> and C<CREATE TABLE>, or the statement resets it and the next diff
finds it again. Compared as the introspection reports them: case aside, the
character set of the table taken from the prefix of its collation. A table
whose default is not known (a target from C<target_from_compiled>) gets what
the column says; a column that says nothing gets nothing.

=head2 as_sql

The C<ALTER TABLE> statement. The names of the table and the column are
quoted with L<DBIO::MySQL::Identifier/quote_ident>.

=head2 add_clause

    my $clause = $op->add_clause;        # ADD COLUMN `c` int(11) NOT NULL
    my $clause = $op->add_clause(1);     # ... NOT NULL AUTO_INCREMENT

The C<ADD COLUMN> clause of an C<add> operation, without the C<ALTER TABLE>.
C<AUTO_INCREMENT> is written only when asked for: the server refuses it on a
column that is no key, so L<DBIO::MySQL::Diff::PrimaryKey> takes the clause of
a column that is its key into the statement that adds the key.

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
