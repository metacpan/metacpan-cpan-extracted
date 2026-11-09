package DBIO::MySQL::Diff::View;
# ABSTRACT: Diff operations for MySQL/MariaDB views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Carp ();
use DBIO::MySQL::Identifier qw(quote_ident);
use DBIO::MySQL::DDL ();

__PACKAGE__->mk_diff_accessors(qw/view_name view_info replaced/);




sub is_view { return (($_[0] // {})->{kind} // '') eq 'view' }


sub without_views {
  my ($tables, @sections) = @_;
  $tables //= {};
  my %view = map { $_ => 1 } grep { is_view($tables->{$_}) } keys %$tables;
  return ($tables, @sections) unless %view;
  return (
    { map { $_ => $tables->{$_} } grep { !$view{$_} } keys %$tables },
    map { my $s = $_; ref $s eq 'HASH' ? { map { $_ => $s->{$_} } grep { !$view{$_} } keys %$s } : $s } @sections,
  );
}


sub model_without_views {
  my ($model) = @_;
  my ($tables, @sections) = without_views(
    $model->{tables}, map { $model->{$_} } qw(columns indexes foreign_keys));
  return { %$model, tables => $tables,
    columns => $sections[0], indexes => $sections[1], foreign_keys => $sections[2] };
}

sub _comparable {
  my ($def) = @_;
  return undef unless defined $def;
  $def =~ s/\s+/ /g;
  $def =~ s/\A //;
  $def =~ s/ \z//;
  return $def;
}


sub diff {
  my ($class, $source, $target) = @_;
  $source //= {};
  $target //= {};

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

    $drop{$name}   = $old if $old;
    $create{$name} = $new if $new;
    $replaced{$name} = 1 if $old && $new;
  }

  # A view that reads a view being replaced is replaced with it (karr k113),
  # transitively, although its own definition is the same: the server lets the
  # view it reads be dropped and answers with 1356 until a view of that name
  # is back, and if the new one lost a column the reader reads, the reader is
  # broken without a word. Created again, the server checks it against the new
  # definition and a reader that no longer fits fails in the apply. An
  # unchanged view has the same reads in both models.
  my %stay = map { $_ => $target->{$_} } grep {
    is_view($source->{$_}) && is_view($target->{$_}) && !$replaced{$_}
  } keys %$target;
  my %fold;
  push @{ $fold{ lc $_ } }, $_ for keys %stay, keys %replaced;
  my $resolve = sub {    # as order_views reads a name: exact, else the one name of that spelling
    my ($r) = @_;
    return $r if exists $stay{$r} || exists $replaced{$r};
    return @{ $fold{ lc $r } // [] } == 1 ? $fold{ lc $r }[0] : undef;
  };
  my @grow = keys %replaced;
  while (defined(my $changed = shift @grow)) {
    for my $name (sort keys %stay) {
      next unless grep { ($resolve->($_) // '') eq $changed }
        DBIO::MySQL::DDL::view_reads($stay{$name}{view_definition});
      $drop{$name}     = $source->{$name};
      $create{$name}   = $target->{$name};
      $replaced{$name} = 1;
      delete $stay{$name};
      push @grow, $name;
    }
  }

  # the order is worked out for the whole set before an op is made: a cycle
  # throws and leaves nothing half done
  my @drop_order   = reverse DBIO::MySQL::DDL::order_views({ map { $_ => $drop{$_}{view_definition} } keys %drop });
  my @create_order = DBIO::MySQL::DDL::order_views({ map { $_ => $create{$_}{view_definition} } keys %create });

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

  return sprintf 'DROP VIEW %s;', quote_ident($self->view_name)
    if $self->action eq 'drop';

  my $def = ($self->view_info // {})->{view_definition};
  Carp::croak(sprintf
    'Cannot create view %s: the target model holds no view definition for it, '
    . 'and a view cannot be written from its columns', $self->view_name)
    unless defined $def && length $def;

  return sprintf 'CREATE VIEW %s AS %s;', quote_ident($self->view_name), $def;
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

DBIO::MySQL::Diff::View - Diff operations for MySQL/MariaDB views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a view-level diff operation: C<CREATE VIEW> or C<DROP VIEW>.

L<DBIO::MySQL::Introspect::Tables> lists a view under C<tables> with
C<< kind => 'view' >>, and the diff used to take it for a table: a view only the
schema declares became a C<CREATE TABLE>, one only the database has became a
C<DROP TABLE> (the server refuses it on a view, error 1051), and its columns
were diffed as a table's. A view is created as a view and removed as
a view, and no table, column or index operation is ever written for one --
L<DBIO::MySQL::Diff::Table>, L<DBIO::MySQL::Diff::Column> and
L<DBIO::MySQL::Diff::Index> leave every entry of kind C<view> alone
(L</without_views>).

=head2 What counts as a changed view

The definition is the C<view_definition> of the table entry, which the
introspection reads from C<information_schema.views>. The server does not hand
back what was written: it rewrites the C<SELECT> (every name in backticks and
qualified with its table, C<AS> for every column, parentheses around a C<WHERE>
on MySQL, its own spelling of the functions) and puts the name of the database
in front of every table. It is the same rewrite for every view, so two views of
one meaning written alike compare equal, and the introspection takes the own
database name out (L<DBIO::MySQL::Introspect::Tables>), because a model built
from a temporary database, as the target of an upgrade is, would otherwise
never equal the live one. Whitespace is set aside in the comparison. A model
that holds no definition on either side has nothing to compare, and the view
counts as unchanged.

A view that is written differently but that the server rewrites to the same
statement is not a changed view; the server's rewrite is the definition of
"the same" here.

MySQL has C<ALTER VIEW> and C<CREATE OR REPLACE VIEW>, MariaDB too, but the
two statements are the pair every driver of the family writes for it, so a
changed definition is a C<drop> followed by a C<create>.

=head1 ATTRIBUTES

=head2 view_name

The name of the view.

=head2 view_info

The view's entry in the C<tables> section of the model it comes from: the
target's for a C<create>, the source's for a C<drop>. A C<create> needs its
C<view_definition>.

=head2 replaced

True on the C<drop> of a changed view: the view is not removed, the C<create>
that follows puts it back with its new definition.
L<DBIO::Diff::Base/classify> counts such a drop as changing, not destructive.

=head1 METHODS

=head2 is_view

    DBIO::MySQL::Diff::View::is_view($table_info)

True for a table entry of kind C<view>.

=head2 without_views

    my ($tables, @sections) = DBIO::MySQL::Diff::View::without_views(
        $tables, $columns, $indexes);

The C<tables> section of a model without its views, and each further section
(C<columns>, C<indexes>, C<foreign_keys>: hashrefs keyed by table name) without
the entries of those views. The arguments are not changed.

=head2 model_without_views

    my $model = DBIO::MySQL::Diff::View::model_without_views($model);

A copy of a whole model with the views taken out of every section.

=head2 diff

    my @ops = DBIO::MySQL::Diff::View->diff($source_tables, $target_tables);

Compares the C<tables> sections of two models, looking at the entries of kind
C<view> only. Returns a C<drop> op for a view only the source has, a C<create>
op for a view only the target has, and both, C<drop> first and marked
L</replaced>, for a view whose definition has changed. All drops come first,
then all creates, each in dependency order (L</The order of the views>).
L<DBIO::MySQL::Diff> puts every C<drop> at the head of the diff and every
C<create> at its end, and keeps the order within each.

=head2 as_sql

C<DROP VIEW `name`;> or C<CREATE VIEW `name` AS definition;>, the name quoted
with L<DBIO::MySQL::Identifier/quote_ident>. A C<create> whose L</view_info>
holds no C<view_definition> throws, naming the view: a view cannot be written
from its columns.

=head2 summary

C<+ view: name> or C<- view: name>. It never throws, for an op L</as_sql>
refuses.

=head2 The order of the views

A view can read another view, and the server refuses C<CREATE VIEW> for one
that reads a view that does not exist (error 1146). So:

=over 4

=item *

the C<create> ops are in the order L<DBIO::MySQL::DDL/order_views> gives for
the views being created, read from the definitions of the target: a view
after the views it reads, otherwise by name. It is the function
L<DBIO::MySQL::DDL/install_ddl> orders its C<CREATE VIEW> statements with, so
the install and the upgrade write one order.

=item *

the C<drop> ops are the reverse of that order for the views being dropped,
read from the definitions of the source: a view before the views it reads.

=item *

a view that reads a view being replaced (a C<drop> and a C<create> of a
changed definition), directly or through other views, is replaced with it,
although its own definition did not change. Measured on MySQL
8.0.30 and MariaDB 11.8.9: the server lets a view be dropped that others
read; the reader answers with error 1356 (invalid references) until a view of
the name exists again, and if the new definition lost a column the reader
reads, it stays broken and says so only when it is queried. The reader is
dropped before the view it reads and created after it, in the order above, so
the server checks it against the new definition when the diff is applied: a
reader that no longer fits fails there, loudly. Its C<drop> is marked
L</replaced>. A view that reads only views that stay as they are is not
touched.

=item *

views that read each other in a cycle are refused with a L<DBIO::Exception>
that names them; no operation is returned.

=back

How a definition is read for what it reads, and what is not recognised, is in
L<DBIO::MySQL::DDL/view_reads>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
