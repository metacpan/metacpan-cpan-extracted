package DBIO::SQLite::Diff::View;
# ABSTRACT: Diff operations for SQLite views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Carp ();
use DBIO::SQLite::Util qw(
  comparable_statement create_name_index quote_identifier sql_tokens
);
use namespace::clean;


__PACKAGE__->mk_diff_accessors(qw/view_name view_info triggers replaced/);



sub diff {
  my ($class, $source, $target, $source_triggers) = @_;
  $source          //= {};
  $target          //= {};
  $source_triggers //= {};

  my %seen;
  my @ops;
  for my $name (sort grep { !$seen{$_}++ } keys %$source, keys %$target) {
    my ($old, $new) = ($source->{$name}, $target->{$name});

    next
      if $old && $new
        && comparable_statement($old->{sql}, 'VIEW')
          eq comparable_statement($new->{sql}, 'VIEW');

    push @ops, $class->new(
      action    => 'drop',
      view_name => $name,
      view_info => $old,
      replaced  => ($new ? 1 : 0),
    ) if $old;

    next unless $new;

    # A replaced view gets back the triggers its DROP took away.
    my $triggers = $old ? $source_triggers->{$name} // {} : {};
    push @ops, $class->new(
      action    => 'create',
      view_name => $name,
      view_info => $new,
      triggers  => [ map { $triggers->{$_}{sql} } sort keys %$triggers ],
    );
  }
  return @ops;
}


sub statements {
  my ($self) = @_;

  return sprintf 'DROP VIEW %s;', quote_identifier($self->view_name)
    if $self->action eq 'drop';

  # Without the statement there is nothing to run, and an empty statement is
  # dropped by the DDL run without a word (karr k73).
  my $sql    = ($self->view_info // {})->{sql} // '';
  my @tokens = sql_tokens($sql);
  Carp::croak(sprintf
    'Cannot create view %s: the target model holds no CREATE VIEW statement '
    . 'for it, and a view cannot be written from its columns', $self->view_name)
    unless defined create_name_index(\@tokens, 'VIEW');

  return map { /;\s*\z/ ? $_ : "$_;" } $sql, @{ $self->triggers // [] };
}


sub as_sql {
  my ($self) = @_;
  return join "\n", $self->statements;
}


sub summary {
  my ($self) = @_;
  return sprintf '%s view: %s', $self->summary_prefix, $self->view_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::View - Diff operations for SQLite views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a view-level diff operation: C<CREATE VIEW> or C<DROP VIEW>.

L<DBIO::SQLite::Introspect::Tables> lists a view under C<tables>, with
C<< kind => 'view' >>, and for a long time the diff took it for a table
there: C<DROP TABLE> for a view that had gone (SQLite: C<use DROP VIEW to
delete view>), C<ALTER TABLE ... ADD COLUMN> for one that selects another
column (C<Cannot add a column to a view>), and nothing at all for one whose
definition had changed but not its columns. A view is a view: it
is created as a view and removed as a view, and no column op, index op or
rebuild is ever written for one.

SQLite has no C<ALTER VIEW>, so a changed definition is a C<drop> followed by
a C<create>.

=head2 What counts as a changed view

Two views of one name are the same view when their C<CREATE VIEW> statements
are the same in the form L<DBIO::SQLite::Util/comparable_statement> gives
them: the view's B<name> is read however it is quoted, whitespace and comments
between two tokens are set aside, and everything else -- the column list, the
C<SELECT> -- has to be the same token for token, in the letter case it is
written in.

So C<CREATE VIEW v AS SELECT 1>, as a database deployed before
L<DBIO::SQLite::DDL> quoted every name holds it, is the view the target
declares as C<CREATE VIEW "v" AS SELECT 1>. C<... AS SELECT "id" FROM item>
against C<... AS SELECT id FROM item> is a changed view. The definition is the
SQL a result class gives as C<view_definition>, which is written as given, so
it comes back the same from a schema nobody changed.

The body of a view is compared and never read. A definition that names a
column its table no longer has is the schema's own: with the name written bare
SQLite refuses the view when it is used, and L<DBIO::SQLite::Deploy> dies
while it builds the target of the upgrade; with the name in double quotes
SQLite reads it as a string, the view is valid and returns that string, after
an upgrade as after a fresh install.

=head2 The triggers of a view

C<DROP VIEW> takes the view's C<INSTEAD OF> triggers with it. A view that
B<goes> loses them. A view that is B<replaced> keeps them: its C<create> op
carries the C<CREATE TRIGGER> statements the live view had
(L<DBIO::SQLite::Introspect::Triggers>) and runs them again behind the
C<CREATE VIEW>. They come from the source model, because a schema cannot
declare a trigger, and are carried as they are -- also where one names a
column the new view no longer has, which SQLite accepts when the trigger is
created and reports when it fires. As everywhere in this driver, triggers are
carried and never compared.

=head2 A view without a statement

A C<create> op is the view's C<CREATE VIEW> statement and nothing else: a
view cannot be written from its columns. An introspected model always has the
statement. A model built by hand that lists a view without one gives the op
nothing to create, and the op is B<refused>: L</statements> and L</as_sql>
throw, in one line that names the view and the reason, and L</summary> still
lists it -- the way of L<DBIO::SQLite::Diff::Column/Changes that are refused>,
with the same consequence: L<DBIO::SQLite::Deploy/apply> throws before it has
run a statement of the diff. A C<drop> op needs no statement.

=head1 ATTRIBUTES

=head2 view_name

The name of the view.

=head2 view_info

The view's entry in the C<tables> section of the model it comes from: the
target's for a C<create>, the source's for a C<drop>. A C<create> needs its
C<sql>.

=head2 triggers

For the C<create> op of a replaced view: an arrayref of the C<CREATE TRIGGER>
statements to run again, without closing semicolons. Empty or absent
otherwise.

=head2 replaced

True on the C<drop> of a changed view: the view is not removed, the C<create>
that follows puts it back with its new definition.
L<DBIO::Diff::Base/classify> counts such a drop as changing, not destructive.
It changes neither the SQL nor the order of the operations.

=head1 METHODS

=head2 diff

    my @ops = DBIO::SQLite::Diff::View->diff(
        $source_views, $target_views, $source_triggers,
    );

Compares two hashrefs of view entries, keyed by view name -- the entries of
the C<tables> sections that have C<< kind => 'view' >>. Returns a C<drop> op
for a view only the source has, a C<create> op for a view only the target
has, and both, C<drop> first, for a view whose definition has changed
(L</What counts as a changed view>).

C<$source_triggers> is the C<triggers> section of the source model; the
C<create> op of a changed view takes that view's statements from it. It may
be left out.

The ops come sorted by view name. L<DBIO::SQLite::Diff> does not run them
side by side: every C<drop> stands at the head of the diff and every
C<create> behind the tables -- see
L<DBIO::SQLite::Diff/The order of the operations>.

=head2 statements

    my @statements = $op->statements;

The statements of the op in the order they have to run, each closed by its
semicolon. A C<drop> is one statement, with the name quoted
(L<DBIO::SQLite::Util/quote_identifier>):

    DROP VIEW "item_names";

A C<create> is the view's C<CREATE VIEW> statement as the target model holds
it, followed by the L</triggers> it carries:

    CREATE VIEW "item_names" AS SELECT "id", "name" FROM "item";
    CREATE TRIGGER item_names_ins INSTEAD OF INSERT ON item_names BEGIN ...; END;

A trigger statement has semicolons inside it, which is why this is a list;
L<DBIO::SQLite::Diff/statements> hands it on as one.

A C<create> whose L</view_info> holds no C<CREATE VIEW> statement throws
(L</A view without a statement>):

    Cannot create view item_names: the target model holds no CREATE VIEW
    statement for it, and a view cannot be written from its columns

=head2 as_sql

L</statements>, joined by newlines. Throws where that does.

=head2 summary

C<+ view: name> or C<- view: name>. It never throws, for an op L</as_sql>
refuses either.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
