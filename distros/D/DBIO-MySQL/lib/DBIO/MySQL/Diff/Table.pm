package DBIO::MySQL::Diff::Table;
# ABSTRACT: Diff operations for MySQL/MariaDB tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::MySQL::Identifier qw(quote_ident quote_table_in);
use DBIO::MySQL::DefaultValue qw(default_sql on_update_sql);
use DBIO::MySQL::Diff::PrimaryKey 'primary_key_columns';
use DBIO::MySQL::Diff::ForeignKey ();
use DBIO::MySQL::Diff::Column ();
use DBIO::MySQL::DDL ();
use DBIO::MySQL::Diff::View ();
use DBIO::MySQL::IndexType ();
use DBIO::Exception ();

__PACKAGE__->mk_diff_accessors(qw(
  table_name table_info old_info columns foreign_keys indexes database
));




sub diff {
  my ($class, $source, $target, $target_columns, $target_fks, $target_indexes, $source_columns, $source_fks) = @_;
  $source_columns //= {};
  $source_fks     //= {};
  $target_columns //= {};
  $target_fks     //= {};
  $target_indexes //= {};

  # a view is no table (karr k79): DBIO::MySQL::Diff::View
  ($source) = DBIO::MySQL::Diff::View::without_views($source);
  ($target) = DBIO::MySQL::Diff::View::without_views($target);

  my @converts;
  for my $name (sort keys %$target) {
    my ($old, $new) = ($source->{$name}, $target->{$name});
    next unless $old;
    next unless defined $old->{table_collation} && defined $new->{table_collation};
    next if lc $old->{table_collation} eq lc $new->{table_collation};
    refuse_unprovable_conversion($name, $old->{table_collation}, $new->{table_collation},
      $source_columns->{$name} // [], $source_fks);
    push @converts, $class->new(
      action     => 'convert',
      table_name => $name,
      table_info => $new,
      old_info   => $old,
    );
  }

  return (@converts, $class->diff_toplevel(
    $source, $target,
    create => sub {
      my ($name) = @_;
      $class->new(
        action       => 'create',
        table_name   => $name,
        table_info   => $target->{$name},
        columns      => $target_columns->{$name} // [],
        foreign_keys => $target_fks->{$name}     // [],
        indexes      => $target_indexes->{$name} // [],
      );
    },
    drop => sub {
      my ($name) = @_;
      $class->new(
        action     => 'drop',
        table_name => $name,
        table_info => $source->{$name},
      );
    },
  ));
}

# MariaDB before 10.6 reports utf8, MySQL 8 and MariaDB 11 utf8mb3.
sub _charset { my $c = lc($_[0] // ''); $c eq 'utf8' ? 'utf8mb3' : $c }


sub refuse_unprovable_conversion {
  my ($table, $old, $new, $columns, $fks) = @_;
  my $refuse = sub {
    DBIO::Exception->throw(sprintf
      "DBIO::MySQL::Diff: table %s has the collation %s and the target gives it %s, "
    . "and ALTER TABLE ... CONVERT TO is refused because it would not keep the data: %s. "
    . "Convert the table by hand, or leave its collation as it is",
      quote_ident($table), $old, $new, $_[0]);
  };

  my ($to) = $new =~ /^([^_]+)_/
    or $refuse->("the character set of the collation $new cannot be told");
  $to = _charset($to);

  my %text;   # the columns CONVERT TO rewrites
  for my $col (@$columns) {
    next unless defined $col->{character_set};
    $text{ $col->{column_name} } = 1;
    next if _charset($col->{character_set}) eq $to;
    my $name = quote_ident($col->{column_name});
    $refuse->("column $name is $col->{character_set} and not $to, and a conversion into a character set other than utf8mb4 may lose characters")
      unless $to eq 'utf8mb4';
    my ($base) = lc($col->{column_type} // $col->{data_type} // '') =~ /^(\w+)/;
    $base //= '';
    $refuse->("column $name is a $base and the server changes its type (tinytext, text and mediumtext become text, mediumtext and longtext) while converting it to $to")
      if $base =~ /^(?:tinytext|text|mediumtext)$/;
    $refuse->("column $name is an $base, and the server drops its members or the data while converting it to $to")
      if $base =~ /^(?:enum|set)$/;
  }

  for my $from (sort keys %$fks) {
    for my $fk (@{ $fks->{$from} }) {
      my $role = $from eq $table && grep({ $text{$_} } @{ $fk->{from_columns} // [] }) ? 'a column of the table references'
               : ($fk->{to_table} // '') eq $table && grep({ $text{$_} } @{ $fk->{to_columns} // [] }) ? 'a column of the table is referenced by'
               : next;
      $refuse->(sprintf "%s %s (constraint %s), and the server converts neither side of such a pair on its own",
        $role, $from eq $table ? quote_ident($fk->{to_table}) : quote_ident($from),
        defined $fk->{constraint_name} ? quote_ident($fk->{constraint_name}) : '(unnamed)');
    }
  }
  return;
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'drop') {
    return sprintf 'DROP TABLE %s;', quote_table_in($self->database, $self->table_name);
  }

  if ($self->action eq 'convert') {
    my $collate = $self->table_info->{table_collation};
    my ($charset) = $collate =~ /^([^_]+)_/;
    return sprintf 'ALTER TABLE %s CONVERT TO CHARACTER SET %s COLLATE %s;',
      quote_table_in($self->database, $self->table_name), $charset, $collate;
  }

  my @col_defs;
  my @pk_cols = primary_key_columns($self->columns);

  for my $col (@{ $self->columns }) {
    my $type = $col->{column_type} || $col->{data_type} || 'text';
    my $def = sprintf '  %s %s', quote_ident($col->{column_name}), $type;
    $def .= DBIO::MySQL::Diff::Column::collation_sql($col, ($self->table_info // {})->{table_collation});
    $def .= ' NOT NULL' if $col->{not_null};
    $def .= ' AUTO_INCREMENT' if $col->{is_auto_increment};
    if (defined $col->{default_value}) {
      $def .= " DEFAULT " . default_sql($col->{default_value}, $col->{default_is_expression});
    }
    $def .= on_update_sql($col->{on_update});
    push @col_defs, $def;
  }

  if (@pk_cols) {
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { quote_ident($_) } @pk_cols);
  }

  # The key of an AUTO_INCREMENT column outside the primary key (karr k107).
  for my $ix (@{ $self->indexes // [] }) {
    my $info = $ix->{index_info};
    my (undef, $type) = DBIO::MySQL::IndexType::index_type_split($info->{index_type});
    push @col_defs, sprintf '  %sKEY %s (%s)%s',
      ($info->{is_unique} ? 'UNIQUE ' : ''), quote_ident($ix->{index_name}),
      join(', ', map { quote_ident($_) } @{ $info->{columns} // [] }), $type // '';
  }

  for my $fk (@{ $self->foreign_keys }) {
    DBIO::MySQL::Diff::ForeignKey::refuse_set_default($self->table_name, $fk->{constraint_name}, $fk);
    # Named like install_ddl names it: the introspected name, or for a model
    # that carries none <table>_<columns>_fk (DBIO::MySQL::DDL::foreign_key_name),
    # never the server's <table>_ibfk_N (karr k106).
    my $fk_name = $fk->{constraint_name}
      // DBIO::MySQL::DDL::foreign_key_name($self->table_name, @{ $fk->{from_columns} });
    my $def = sprintf '  CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)',
      quote_ident($fk_name),
      join(', ', map { quote_ident($_) } @{ $fk->{from_columns} }),
      quote_ident($fk->{to_table}),
      join(', ', map { quote_ident($_) } @{ $fk->{to_columns} });
    # The actions, as DBIO::MySQL::Diff::ForeignKey writes them (karr k106).
    $def .= " ON UPDATE $fk->{on_update}" if $fk->{on_update} && $fk->{on_update} ne 'NO ACTION';
    $def .= " ON DELETE $fk->{on_delete}" if $fk->{on_delete} && $fk->{on_delete} ne 'NO ACTION';
    push @col_defs, $def;
  }

  my $info    = $self->table_info // {};
  my $engine  = $info->{engine}          || 'InnoDB';
  # The character set and collation install_ddl gives a table that names none
  # (karr k82): without COLLATE the server fills in its own default, and the
  # text columns of the table differ from the schema in every later diff.
  my ($charset, $collate) = ($info->{table_collation} && $info->{table_collation} =~ /^([^_]+)_/)
    ? ($1, $info->{table_collation})
    : (DBIO::MySQL::DDL::default_charset(), DBIO::MySQL::DDL::default_collation());

  return sprintf "CREATE TABLE %s (\n%s\n) ENGINE=%s DEFAULT CHARSET=%s COLLATE=%s;",
    quote_table_in($self->database, $self->table_name), join(",\n", @col_defs), $engine, $charset, $collate;
}


sub summary {
  my ($self) = @_;
  if ($self->action eq 'convert') {
    return sprintf '~ table collation: %s (%s -> %s)', $self->table_name,
      $self->old_info->{table_collation}, $self->table_info->{table_collation};
  }
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '%s table: %s', $prefix, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff::Table - Diff operations for MySQL/MariaDB tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a table-level diff operation in MySQL/MariaDB: C<CREATE
TABLE>, C<DROP TABLE> or, for a table whose collation changes, C<ALTER TABLE
... CONVERT TO> (see L</The collation of an existing table>). C<create> ops carry the target columns and FKs
so C<as_sql> can render the full inline definition (parallel to
L<DBIO::SQLite::Diff::Table>).

The foreign keys a C<create> op carries are the ones its C<CREATE TABLE> is to
have, and L<DBIO::MySQL::Diff> chooses them: a foreign key that needs an index
the same diff creates (a unique key of a table it creates, say) is left out and
added after the index, where the server would refuse it here; and
so is one whose columns an index the diff creates on the table covers, where
the server would make a second index over them. The
C<CREATE TABLE> carries no index but the primary key, and a C<DROP TABLE>
comes after the C<DROP FOREIGN KEY> of every constraint that references the
table.

The one exception to the primary key being the only key of a C<CREATE TABLE>: an
C<AUTO_INCREMENT> column that is not in the primary key has to be a key at the
moment the table is created (the server refuses it otherwise, "there can be only
one auto column and it must be defined as a key"). L<DBIO::MySQL::Diff> hands such
a table the index the target has over the column (C<indexes>, hashrefs
C<< { index_name, index_info } >>), and it stands in the C<CREATE TABLE> as
C<UNIQUE KEY> or C<KEY>, not as a C<CREATE INDEX> after it, so the table that an
upgrade creates is the table C<install_ddl> creates.

=head2 The collation of an existing table

The character set and collation of a table are part of the target model
(C<mysql_charset> and C<mysql_collate> of the result class, C<table_collation>
of L<DBIO::MySQL::Introspect::Tables>); the C<CREATE TABLE> of a new table
writes them. A table that exists with another collation is changed with

    ALTER TABLE `t` CONVERT TO CHARACTER SET x COLLATE y;

 -- but only where the data provably survives. The statement
rewrites every text column of the table, and what it does to the data was
measured on MySQL 8.0.30 and MariaDB 11.8.9 (both behave alike unless said):

=over

=item * Same character set, other collation (C<utf8mb4_unicode_ci> to
C<utf8mb4_bin> and back): the bytes stay, nothing is re-encoded. Umlauts,
CJK and 4-byte characters were identical afterwards; C<FULLTEXT> indexes kept
matching; C<BLOB>, C<VARBINARY> and C<BINARY> columns are not touched; a column
with a collation of its own gets the table's (the model has no per-column
collation); C<TINYTEXT>/C<TEXT> keep their type. A unique key whose values
collide under the new collation (C<abc>, C<ABC> from C<_bin> to C<_ci>) is
refused by the server (1062, "Duplicate entry"), atomically -- the table was
unchanged afterwards; that error is the server's, a diff cannot know it in
advance.

=item * Another character set, target C<utf8mb4>: widening, the characters
are kept (C<latin1> with umlauts and C<utf8mb3> with Japanese text were
identical afterwards). Two things are not safe and are refused instead:
C<TINYTEXT>, C<TEXT> and C<MEDIUMTEXT> columns are silently promoted to
C<TEXT>, C<MEDIUMTEXT> and C<LONGTEXT> (the type changes, so a later diff
would turn it back and cut), and C<ENUM> / C<SET> columns of C<latin1> lose
their non-ASCII members (MySQL 8.0.30 left the definition C<enum('','b')> and
emptied the data without an error; MariaDB refused with "Data truncated").
An index over a long C<VARCHAR> can exceed the key length; MySQL refuses
(1071, atomically), MariaDB keeps the statement and shortens the key to a
prefix.

=item * Any other target character set (C<latin1>, C<utf8mb3>, ...) for a
column that has another one: narrowing. Characters outside the target are
lost (with strict mode the server refuses, "Incorrect string value", and the
table stays; a session without it wrote C<?> for each of them and the data
differed afterwards). Refused.

=item * A foreign key that has a text column of the table on either side:
the server refuses the conversion of either table of the pair on its own
(MySQL: "Referencing column ... and referenced column ... are incompatible",
MariaDB: "Cannot change column ... used in a foreign key constraint"), and one
statement cannot convert both. Refused.

=back

A refusal is a L<DBIO::Exception> that names the table, both collations and the
column or constraint, thrown while the diff is built, before any statement ran.
The columns of a converted table are not compared for character set and
collation: the conversion gives them the collation of the target.

=head1 METHODS

=head2 diff

    my @ops = DBIO::MySQL::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_fks,
        $target_indexes, $source_columns, $source_fks,
    );

The last two are the columns and foreign keys of the source, by table; they
are what the refusals of a collation change look at.

=head2 refuse_unprovable_conversion

    DBIO::MySQL::Diff::Table::refuse_unprovable_conversion(
        $table, $old_collation, $new_collation, $source_columns, $source_fks);

Throws a L<DBIO::Exception> when C<CONVERT TO> would not keep the data of the
table, see L</The collation of an existing table>. Returns nothing otherwise.

=head2 as_sql

The C<CREATE TABLE>, C<DROP TABLE> or C<ALTER TABLE ... CONVERT TO> statement. Every name in it is quoted
with L<DBIO::MySQL::Identifier/quote_ident>. A foreign key with a C<SET DEFAULT>
action throws (L<DBIO::MySQL::Diff::ForeignKey/refuse_set_default>).

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
