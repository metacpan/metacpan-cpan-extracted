package DBIO::Oracle::Diff::View;
# ABSTRACT: Diff operations for Oracle views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::Oracle::Identifier ();

__PACKAGE__->mk_diff_accessors(qw(view_name definition columns));



sub table_name { $_[0]->view_name }


sub diff {
  my ($class, $source_tables, $target_tables, $source_views, $target_views) = @_;
  $_ //= {} for $source_tables, $target_tables, $source_views, $target_views;

  my $is_view = sub { ( ref $_[0] eq 'HASH' && ( $_[0]{kind} // '' ) eq 'view' ) };

  my (@create, @alter, @drop);
  for my $name (sort keys %$target_tables) {
    next unless $is_view->($target_tables->{$name});
    my $def = $target_views->{$name}{definition};
    my $cols = $target_views->{$name}{columns};
    DBIO::Exception->throw(
      "DBIO::Oracle::Diff refuses to create view $name: the model carries no "
      . 'view definition to create it from')
      unless defined $def && length $def;

    if (!exists $source_tables->{$name}) {
      push @create, $class->new(action => 'create', view_name => $name, definition => $def, columns => $cols);
    }
    elsif ($is_view->($source_tables->{$name})) {
      my $was = $source_views->{$name}{definition};
      DBIO::Exception->throw(
        "DBIO::Oracle::Diff refuses to compare view $name: the source model "
        . 'carries no view definition to compare it with')
        unless defined $was && length $was;
      my $was_cols = $source_views->{$name}{columns};
      push @alter, $class->new(action => 'alter', view_name => $name, definition => $def, columns => $cols)
        if _normalize($was) ne _normalize($def)
        || ( $was_cols && $cols && join("\0", @$was_cols) ne join("\0", @$cols) );
    }
    # a table that became a view: DBIO::Oracle::Diff::Table refuses it
  }

  for my $name (sort keys %$source_tables) {
    next unless $is_view->($source_tables->{$name}) && !exists $target_tables->{$name};
    push @drop, $class->new(action => 'drop', view_name => $name);
  }

  # A view that rests on another view is written after it, dropped before it
  # (karr k65): the target's dependencies order what is written, the source's
  # what is dropped. Only the views of the run count; a view it rests on that
  # is not written needs no edge.
  my @write = _dependency_order(
    [ @create, @alter ], $target_views, 'create or replace',
  );
  @drop = reverse _dependency_order(\@drop, $source_views, 'drop', 1);

  return (@drop, @write);
}

# The ops, the ones a view rests on first; ties in the order of the names (the
# reverse of it when $descending, for a list that is reversed afterwards).
# A cycle is refused with the names of its views.
sub _dependency_order {
  my ($ops, $views, $what, $descending) = @_;
  my %op = map { $_->view_name => $_ } @$ops;

  my (@order, %state);
  my $visit; $visit = sub {
    my ($name, @path) = @_;
    return if ( $state{$name} // '' ) eq 'done';
    if ( ( $state{$name} // '' ) eq 'open' ) {
      my @cycle = ( @path[ ( grep { $path[$_] eq $name } 0 .. $#path )[0] .. $#path ], $name );
      DBIO::Exception->throw(
        "DBIO::Oracle::Diff refuses to $what views that rest on each other (cycle): "
        . join(' -> ', @cycle));
    }
    $state{$name} = 'open';
    my @deps = grep { exists $op{$_} && $_ ne $name } @{ $views->{$name}{depends_on} // [] };
    $visit->($_, @path, $name)
      for $descending ? reverse sort(@deps) : sort(@deps);
    $state{$name} = 'done';
    push @order, $op{$name};
  };
  $visit->($_) for $descending ? reverse sort(keys %op) : sort(keys %op);
  return @order;
}

# Whitespace and a trailing semicolon are not a difference; a string literal and
# a quoted identifier are kept as they are.
sub _normalize {
  my ($sql) = @_;
  $sql =~ s/\A\s+//;
  $sql =~ s/(?:\s*;)*\s*\z//;
  my @parts = split /('(?:[^']|'')*'|"(?:[^"]|"")*")/, $sql, -1;
  for my $i (grep { !($_ % 2) } 0 .. $#parts) {
    $parts[$i] =~ s/\s+/ /g;
  }
  return join '', @parts;
}


sub as_sql {
  my ($self) = @_;
  my $name = DBIO::Oracle::Identifier::quote_table($self->view_name);
  return sprintf 'DROP VIEW %s;', $name if $self->action eq 'drop';
  my $cols = $self->columns;
  my $list = $cols && @$cols
    ? ' (' . join(', ', map { DBIO::Oracle::Identifier::quote($_) } @$cols) . ')'
    : '';
  return sprintf 'CREATE OR REPLACE VIEW %s%s AS %s;', $name, $list, $self->definition;
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

DBIO::Oracle::Diff::View - Diff operations for Oracle views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Compares the views of two models: C<CREATE OR REPLACE VIEW> for a
view only the target has and for one whose definition changed, C<DROP VIEW>
for one only the source has. The definition is the C<views> section of the
model, per view C<< { view_name => $name, definition => $sql, columns => \@names, depends_on => \@views } >>
(L<DBIO::Oracle::Introspect::Views>); the kind of an object is the C<kind> of
its entry in C<tables>. The statement is C<CREATE OR REPLACE VIEW "name"
("col", ...) AS definition>, the definition as the target model has it and the
column list from C<columns> (below). A changed view is
replaced as a whole: its columns are not altered one by one, and
L<DBIO::Oracle::Diff::Column> leaves the columns of a view alone.

L<DBIO::Oracle::Diff> puts the drops before the operations on tables and the
creations and replacements after them. A view that rests on another view is
ordered by the dependency (the C<depends_on> list of its entry in C<views>,
read from C<all_dependencies>): the views written (created or
replaced) rest-on first, in the order of the B<target> model's dependencies;
the views dropped dependents first, in the order of the B<source> model's. A
view that rests on one this run does not write needs no edge, and a dependency
on a view of another schema is the key C<schema.view>. Views that rest on each
other (a cycle, possible only in a model written by hand) are refused with a
L<DBIO::Exception> naming them, before the first statement.

B<The column list.> The text of a view does not hold the names given by
C<CREATE VIEW v (a, b) AS ...>; they are only in the columns of the view. The
model therefore carries them (C<columns>, the names from C<all_tab_columns> in
C<COLUMN_ID> order, as Oracle spells them) and the diff writes them in front of
C<AS>, each quoted as the model has it, so an alias that came from a column
list survives the replace. A view whose query is the same but whose column list
differs (a name or the order) is changed. A model without C<columns> (written by
hand) gets a statement without a list, and its column list is not compared.

B<Comparison.> Two definitions are equal when they are equal after leading and
trailing whitespace and a trailing semicolon are removed and every run of
whitespace outside a string literal (C<'...'>) or a quoted identifier
(C<"...">) is one space. Everything else is compared as written, case
included.

B<What Oracle stores.> The text in C<all_views.text> is what Oracle keeps of
the statement, not the statement. Measured on Oracle 23ai Free (t/57,
t/87):

=over 4

=item * Only the query is kept: C<CREATE [OR REPLACE] [FORCE] VIEW name AS> and
the whitespace behind C<AS> are gone, and so is a trailing semicolon. A
comment (C</* ... */>) in front of the C<SELECT> is dropped; a C<-- ...>
comment inside the query stays.

=item * A column list C<CREATE VIEW v (a, b) AS ...> is not part of the text:
a view written with one reads back as the bare query, and the names are only
in the view's columns, which the model carries as C<columns> (see above).

=item * C<SELECT *> is expanded to the columns, written C<"a","b"> without a
space after the comma. C<WITH READ ONLY> and C<WITH CHECK OPTION> stay in the
text.

=item * Case and the whitespace inside the query are kept as written.

=back

Both models of a diff come from the server (the live schema and the temporary
user of L<DBIO::Oracle::Deploy>), so both have passed through this rewriting
and equal queries compare equal. A model written by hand is compared with one
read from a server only as far as its text agrees with what the server stores.
A view whose definition is missing (not set, C<undef> or empty) in the target
model, or in the source model of a view both have, is refused with a
L<DBIO::Exception> naming the view, before the first statement: the diff does
not guess whether it changed, and it does not replace it every time. A view that
is only dropped needs no definition.

=head1 ATTRIBUTES

=head2 view_name

The key of the view: a bare name, or C<schema.view> for a view of another
schema, written C<"schema"."view">.

=head2 definition

The defining query, for a C<create> or C<alter> op.

=head2 columns

The names of the columns of the view in order (an ArrayRef), for a C<create> or
C<alter> op; C<undef> when the model carries none.

=head1 METHODS

=head2 table_name

The same as L</view_name>: every operation of a diff answers C<table_name>
with the key of the object it is on (the conformance runner and the callers
that filter operations by object ask for it).

=head2 diff

    my @ops = DBIO::Oracle::Diff::View->diff(
        $source_tables, $target_tables, $source_views, $target_views,
    );

The C<tables> and C<views> sections of the two models. Returns C<create> ops
for the views only the target has, C<alter> ops for those whose definition
changed, and C<drop> ops for those only the source has, each group in the order
of the names. The ops are told apart by C<action>; the caller places the drops
before the table operations and the others after them.

=head2 as_sql

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
