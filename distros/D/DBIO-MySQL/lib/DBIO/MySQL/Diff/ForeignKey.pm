package DBIO::MySQL::Diff::ForeignKey;
# ABSTRACT: Diff operations for MySQL/MariaDB foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_fk_fields);
use DBIO::Exception ();
use DBIO::MySQL::Identifier qw(quote_ident quote_table_in);
use DBIO::MySQL::DDL ();

__PACKAGE__->mk_diff_accessors(qw(
  table_name constraint_name fk_info database replaced
));



sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  $source //= {};
  $target //= {};

  # diff_nested walks the tables that are keys of the target it is given, and a
  # table without a foreign key is not one: neither the introspection nor
  # target_from_compiled gives it an entry. A table whose last foreign key is
  # gone would so never be looked at, and its DROP FOREIGN KEY never written
  # (karr k86). So every table that had foreign keys gets an entry here, an
  # empty one unless the target has its own. Which of them is walked is still
  # decided by the tables of the two models (scope 'both'): not a table the
  # diff creates, and not one it drops.
  my %target = ((map { $_ => [] } keys %$source), %$target);

  my @ops = $class->diff_nested(
    $source, \%target,
    index_by      => 'constraint_name',
    source_tables => $source_tables,
    target_tables => $target_tables // $target,
    changed_when  => \&changed_fk_fields,
    on_new => sub {
      my ($table_name, $constraint_name, $fk_info) = @_;
      $class->new(action => 'add', table_name => $table_name,
        constraint_name => $constraint_name, fk_info => $fk_info);
    },
    on_changed => sub {
      my ($table_name, $constraint_name, $old_info, $new_info) = @_;
      (
        $class->new(action => 'drop', table_name => $table_name, replaced => 1,
          constraint_name => $constraint_name, fk_info => $old_info),
        $class->new(action => 'add',  table_name => $table_name,
          constraint_name => $constraint_name, fk_info => $new_info),
      );
    },
    on_gone => sub {
      my ($table_name, $constraint_name, $fk_info) = @_;
      $class->new(action => 'drop', table_name => $table_name,
        constraint_name => $constraint_name, fk_info => $fk_info);
    },
  );

  # A table the diff drops, and a foreign key of it into another table the
  # diff drops: the server refuses the DROP TABLE of the referenced one while
  # the constraint is there (3730 on MySQL, 1451 on MariaDB), and which of the
  # two goes first is a matter of their names. The constraint is dropped
  # first, with the others (karr k94). A foreign key into a table that stays,
  # or into itself, goes with the DROP TABLE as ever.
  if ($target_tables) {
    my %dropped = map { $_ => 1 }
      grep { !exists $target_tables->{$_} } keys %{ $source_tables // {} };
    for my $table_name (sort grep { $dropped{$_} } keys %$source) {
      for my $fk_info (@{ $source->{$table_name} }) {
        next unless $dropped{ $fk_info->{to_table} } && $fk_info->{to_table} ne $table_name;
        push @ops, $class->new(action => 'drop', table_name => $table_name,
          constraint_name => $fk_info->{constraint_name}, fk_info => $fk_info);
      }
    }
  }

  return @ops;
}


sub refuse_set_default {
  my ($table, $constraint, $info) = @_;
  for my $attr (qw(on_update on_delete)) {
    my $value = $info->{$attr};
    next unless defined $value && $value =~ /\A\s*SET[\s_]+DEFAULT\s*\z/i;
    DBIO::Exception->throw(sprintf
      "foreign key of %2\$s, constraint %1\$s, has %3\$s %4\$s: MySQL and MariaDB accept SET DEFAULT but never run it "
      . "(the server acts as RESTRICT), so it is refused",
      defined $constraint ? "'$constraint'" : '(unnamed)', $table, $attr, $value);
  }
}


sub as_sql {
  my ($self) = @_;
  my $tbl  = quote_table_in($self->database, $self->table_name);

  if ($self->action eq 'add') {
    # A foreign key the introspection gave no name (a hand made model) gets the
    # name install_ddl would give it, as in a CREATE TABLE (karr k106).
    my $info = $self->fk_info;
    my $name = quote_ident($self->constraint_name
      // DBIO::MySQL::DDL::foreign_key_name($self->table_name, @{ $info->{from_columns} }));
    refuse_set_default($self->table_name, $self->constraint_name, $info);
    my $from = join(', ', map { quote_ident($_) } @{ $info->{from_columns} });
    my $to   = join(', ', map { quote_ident($_) } @{ $info->{to_columns} });
    my $sql  = sprintf
      'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)',
      $tbl, $name, $from, quote_ident($info->{to_table}), $to;
    $sql .= " ON UPDATE $info->{on_update}" if $info->{on_update} && $info->{on_update} ne 'NO ACTION';
    $sql .= " ON DELETE $info->{on_delete}" if $info->{on_delete} && $info->{on_delete} ne 'NO ACTION';
    return "$sql;";
  }
  return sprintf 'ALTER TABLE %s DROP FOREIGN KEY %s;', $tbl, quote_ident($self->constraint_name);
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'add' ? '+' : '-';
  return sprintf '  %sfk: %s on %s', $prefix, $self->constraint_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff::ForeignKey - Diff operations for MySQL/MariaDB foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a foreign key diff operation: C<ADD CONSTRAINT> or
C<DROP FOREIGN KEY>. FKs that already exist on a brand-new table are
created inline by L<DBIO::MySQL::Diff::Table> (but see below), and those of a
table that is dropped go with its C<DROP TABLE> (but see below) -- this module
otherwise handles FK changes on tables that exist in both source and target.

FK identity is by C<constraint_name>. A definition change becomes a
drop-then-add pair (MySQL has no C<ALTER FOREIGN KEY>); the drop of such a pair
answers true to C<replaced>, so L<DBIO::Diff::Base/classify> counts it as
changing, not as a removal that needs C<allow_destructive>. The names are the fixed
ones L<DBIO::MySQL::DDL> gives (C<< <table>_<columns>_fk >>,
L<DBIO::MySQL::DDL/foreign_key_name>), so an install and an upgrade agree on
them; a constraint the server named C<< <table>_ibfk_N >> is dropped and added
again under its fixed name by the next upgrade.

The drops stand first in a diff, before the tables and the indexes
(L<DBIO::MySQL::Diff> does that), and the adds last. The server refuses to
drop the table a constraint references, and the index it needs, while the
constraint is there. So a constraint of a table that is dropped, into another
table that is dropped as well, gets its C<DROP FOREIGN KEY> too, and the two
C<DROP TABLE> statements are free of each other. The adds include the foreign
keys of a table the diff creates that need an index the same diff creates:
L<DBIO::MySQL::Diff> takes those out of the C<CREATE TABLE>, which the server
would refuse; and those whose columns an index the diff creates on the new
table covers, which the server would give a second index.

=head1 METHODS

=head2 diff

    my @ops = DBIO::MySQL::Diff::ForeignKey->diff(
        $source_fks, $target_fks, $source_tables, $target_tables,
    );

C<$source_fks> and C<$target_fks> are the C<foreign_keys> sections of the two
models, C<$source_tables> and C<$target_tables> their C<tables> sections. It is
the tables that say which table is in both models; a section of foreign keys
cannot, because it has no entry for a table without one
(L<DBIO::MySQL::Introspect::ForeignKeys/fetch>). A table that is in both models
and has lost every foreign key it had gets a C<DROP FOREIGN KEY> for each of
them, whether C<$target_fks> names it or not.

Without C<$target_tables>, the tables C<$target_fks> names are taken for the
tables of the target. A table with foreign keys in C<$source_fks> only then
counts as dropped, and nothing is written for it.

=head2 refuse_set_default

    DBIO::MySQL::Diff::ForeignKey::refuse_set_default($table, $constraint, $fk_info);

Throws a L<DBIO::Exception> naming table, constraint, clause and value when
the C<on_delete> or C<on_update> of C<$fk_info> is C<SET DEFAULT>. Both
servers take that DDL and never run the action (MySQL acts as C<RESTRICT>,
MariaDB stores C<RESTRICT>), so it is refused where the diff writes a foreign
key -- here and in L<DBIO::MySQL::Diff::Table> -- the same way
L<DBIO::MySQL::DDL> refuses it. This is the only check of the actions the diff
makes: any other value is the introspected one and is written as it stands.

=head2 as_sql

The C<ALTER TABLE> statement. The names of the constraint, of both tables and
of their columns are quoted with L<DBIO::MySQL::Identifier/quote_ident>. A
C<SET DEFAULT> action throws (L</refuse_set_default>).

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
