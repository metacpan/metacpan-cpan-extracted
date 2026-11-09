package DBIO::DB2::Diff::View;
# ABSTRACT: Diff operations for DB2 views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Carp ();
use DBIO::DB2::DDL qw(_db2_quote_ident);

__PACKAGE__->mk_diff_accessors(qw/view_name view_info replaced/);




sub is_view { return ((($_[0] // {})->{kind}) // '') eq 'view' }

sub _comparable {
  my ($def) = @_;
  return undef unless defined $def;
  $def =~ s/\s+/ /g;
  $def =~ s/\A //;
  $def =~ s/ \z//;
  return $def;
}


sub diff {
  my ($class, $source, $target, $schema) = @_;
  $source //= {};
  $target //= {};

  # The schema the operations run in is the live one, the source model's: its
  # entries carry it (Introspect::Tables). A qualified read in a definition is
  # judged against it (karr k55); a model without an entry has no schema to give.
  ($schema) = grep { defined } map { $_->{schema} } map { $source->{$_} } sort keys %$source
    unless defined $schema;

  my %seen;
  my (%drop, %create, %replaced);
  for my $name (sort grep { !$seen{$_}++ } keys %$source, keys %$target) {
    my $old = is_view($source->{$name}) ? $source->{$name} : undef;
    my $new = is_view($target->{$name}) ? $target->{$name} : undef;
    next unless $old || $new;

    if ($old && $new) {
      my ($was, $will) = map { _comparable($_->{view_definition}) } $old, $new;
      next if !defined $was || !defined $will || $was eq $will;
    }

    $drop{$name}     = $old if $old;
    $create{$name}   = $new if $new;
    $replaced{$name} = 1 if $old && $new;
  }

  # A view that reads a view being replaced is replaced with it (karr k54),
  # transitively, although its own definition is the same. An unchanged view
  # has the same reads in both models.
  my %stay = map { $_ => $target->{$_} } grep {
    is_view($source->{$_}) && is_view($target->{$_}) && !$replaced{$_}
  } keys %$target;
  my @grow = keys %replaced;
  while (defined(my $changed = shift @grow)) {
    for my $name (sort keys %stay) {
      next unless grep { $_ eq $changed } DBIO::DB2::DDL::view_dependencies(
        [ keys %stay, keys %replaced ], $name, $stay{$name}{view_definition}, $schema);
      $drop{$name}     = $source->{$name};
      $create{$name}   = $target->{$name};
      $replaced{$name} = 1;
      delete $stay{$name};
      push @grow, $name;
    }
  }

  # the order is worked out for the whole set before an op is made: a cycle
  # throws and leaves nothing half done
  my @drop_order   = reverse DBIO::DB2::DDL::order_views({ map { $_ => $drop{$_}{view_definition} } keys %drop }, $schema);
  my @create_order = DBIO::DB2::DDL::order_views({ map { $_ => $create{$_}{view_definition} } keys %create }, $schema);

  return (
    (map { $class->new(
      action    => 'drop',
      view_name => $_,
      view_info => $drop{$_},
      replaced  => ($replaced{$_} ? 1 : 0),
    ) } @drop_order),
    (map { $class->new(
      action    => 'create',
      view_name => $_,
      view_info => $create{$_},
    ) } @create_order),
  );
}


sub as_sql {
  my ($self) = @_;

  return sprintf 'DROP VIEW %s;', _db2_quote_ident($self->view_name)
    if $self->action eq 'drop';

  my $def = ($self->view_info // {})->{view_definition};
  Carp::croak(sprintf
    'Cannot create view %s: the target model holds no view definition for it, '
    . 'and a view cannot be written from its columns', $self->view_name)
    unless defined $def && length $def;

  return sprintf 'CREATE VIEW %s %s;', _db2_quote_ident($self->view_name), $def;
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

DBIO::DB2::Diff::View - Diff operations for DB2 views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a view-level diff operation: C<CREATE VIEW> or C<DROP VIEW>.

L<DBIO::DB2::Introspect::Tables> lists a view under C<tables> with C<< kind =>
'view' >> and its C<view_definition>. A view is created as a view and removed
as a view, and no table, column or index operation is ever written for one --
L<DBIO::DB2::Diff::Table> and L<DBIO::DB2::Diff::Column> leave every entry of
kind C<view> alone (ADR 0011).

=head2 What counts as a changed view

The C<view_definition> is what the catalog holds of the C<CREATE VIEW> statement
after the view's name (C<SYSCAT.VIEWS.TEXT>, the text as it was written): normally
C<AS SELECT ...>, with the column list in front when the view was made with one.
The name is cut off with the schema in front of it, so the view of the live schema
and the one of the compare schema (C<DBIO_TEST_E<lt>pidE<gt>>, ADR 0006) compare by
what they read, not by where they sit. Whitespace is set aside; everything else has
to be the same, letter for letter. A model that holds no definition on either side
has nothing to compare and the view counts as unchanged.

Db2 has C<CREATE OR REPLACE VIEW>, but the pair every driver of the family writes is
a C<drop> followed by a C<create>, and so a changed definition is.

=head2 The order of the views

A view can read another view, and the server refuses C<CREATE VIEW> for one that
reads a view that does not exist (SQL0204N). So (as in dbio-mysql):

=over 4

=item *

the C<create> ops are in the order L<DBIO::DB2::DDL/order_views> gives for the views
being created, read from the definitions of the target: a view after the views it
reads, otherwise by name. It is the function L<DBIO::DB2::DDL/install_ddl> orders its
C<CREATE VIEW> statements with, so install and upgrade write one order.

=item *

the C<drop> ops are the reverse of that order for the views being dropped, read from
the definitions of the source: a view before the views it reads.

=item *

a view that reads a view being replaced (a C<drop> and a C<create> of a changed
definition), directly or through other views, is replaced with it, although its own
definition did not change. Db2 would otherwise refuse the C<DROP VIEW> of the base or
leave the reader inoperative (SQL0204N on its next use). The reader is dropped before
the view it reads and created after it, so the server checks it against the new
definition when the diff is applied: a reader that no longer fits fails there, loudly.
Its C<drop> is marked L</replaced>. A view that reads only views that stay as they are
is not touched.

=item *

views that read each other in a cycle are refused with a L<DBIO::Exception> that names
them, before any operation is returned.

=back

How a definition is read for what it reads, and what is not recognised, is in
L<DBIO::DB2::DDL/view_reads>. Two things there decide an order: the name of
a common table expression is no view, and a read qualified with a schema is a view of
the set only when the qualifier is the live schema -- the C<schema> the entries of the
source model carry, which is where the operations run (ADR 0006). A model with no entry
gives none, and a qualified read of a view of the set is then refused with a
L<DBIO::Exception>, like a cycle, before any operation is returned.

=head1 ATTRIBUTES

=head2 view_name

The name of the view.

=head2 view_info

The view's entry in the C<tables> section of the model it comes from: the target's for
a C<create>, the source's for a C<drop>. A C<create> needs its C<view_definition>.

=head2 replaced

True on the C<drop> of a changed view: the view is not removed, the C<create> that
follows puts it back with its new definition. L<DBIO::Diff::Base/classify> counts such
a drop as changing, not destructive.

=head1 METHODS

=head2 is_view

    DBIO::DB2::Diff::View::is_view($table_info)

True for a table entry of kind C<view>.

=head2 diff

    my @ops = DBIO::DB2::Diff::View->diff($source_tables, $target_tables);
    my @ops = DBIO::DB2::Diff::View->diff($source_tables, $target_tables, $schema);

Compares the C<tables> sections of two models, looking at the entries of kind C<view>
only. Returns a C<drop> op for a view only the source has, a C<create> op for a view
only the target has, and both, C<drop> first and marked L</replaced>, for a view whose
definition has changed. All drops come first, then all creates, each in dependency
order (L</The order of the views>). An optional third argument names the live schema
when the source model cannot (L<DBIO::DB2::DDL/view_dependencies>). L<DBIO::DB2::Diff> puts every C<drop> at the head
of the diff and every C<create> at its end, and keeps the order within each.

=head2 as_sql

C<DROP VIEW "name";> or C<CREATE VIEW "name" AS definition;>, the name quoted. A
C<create> whose L</view_info> holds no C<view_definition> throws, naming the view: a
view cannot be written from its columns.

=head2 summary

C<+ view: name> or C<- view: name>. It never throws, for an op L</as_sql> refuses.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
