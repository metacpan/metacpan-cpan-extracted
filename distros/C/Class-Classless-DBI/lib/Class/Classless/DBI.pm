package Class::Classless::DBI;
use strict;
use warnings;

our $VERSION = '0.02';

use Class::Classless;
#use SQL::Interpolate TRACE_SQL => 1;

our $ROOT = $Class::Classless::ROOT->clone;
my $meth = $ROOT->{METHODS};
$meth->{delete_from_table} = \&delete_from_table;
$meth->{insert_into_table} = \&insert_into_table;
$meth->{select_from_table} = \&select_from_table;
$meth->{update_table} = \&update_table;

$meth->{make_where_clause} = \&make_where_clause;
$meth->{make_from_clause} = \&make_from_clause;

# TO DO:
# - Pester David about SQL::Interpolate

sub delete_from_table {

  my($self,$next,$vars) = @_;

  return $self->dbx->do('
    DELETE FROM', $self->table, 'WHERE',
      @{ $self->make_where_clause($vars) }
  );

}

sub insert_into_table {

  my($self,$next,$vars) = @_;
  my $values = $vars->{from} = $vars->{values};
  my $columns = $vars->{columns};

  my $row = ref $values eq 'ARRAY' ? $values->[0] : $values;
  $self->dbx->do('
    INSERT IGNORE INTO', $self->table,
        '(', join(',', map {$columns->{$_} || $_} keys %$row), ')
    SELECT * FROM', @{ $self->make_from_clause($vars) }
  );

}

sub select_from_table {

  my($self,$next,$vars) = @_;
  my(@select,@group);
  my $select = $vars->{select};
  my $group = $vars->{group};
  if($select) {
    @select = map {$_,','} @$select;
    pop @select;
  } else {
    @select = qw(*);
  }
  if($group) {
    @group = ('GROUP BY', map {$_,','} @$group);
    pop @group;
  } elsif($select) {
    @group = ('GROUP BY', @select);
  } else {
    @group = ();
  }

  return $self->dbx->selectall_arrayref('
    SELECT', @select, 'FROM', $self->table, '
    WHERE', @{ $self->make_where_clause($vars) },
    @group,
    DBIx::Interpolate::attr(Columns=>{})
  );

}

sub update_table {

  my($self,$next,$vars) = @_;

  return $self->dbx->do('
    UPDATE', $self->table, 'SET', $vars->{values}, '
    WHERE', @{ $self->make_where_clause($vars) }
  );

}

sub make_where_clause {

  my($self,$next,$vars) = @_;
  my $where = $vars->{where} || return ['1=1'];
  my $columns = $vars->{columns};
  my @ret = ();

  foreach my $subtable (ref $where eq 'ARRAY' ? @$where : $where) {
    push @ret, map {
      ({$columns->{$_} || $_ => $subtable->{$_}}, 'AND')
    } keys %$subtable;
    scalar %$subtable ? pop @ret : push @ret, '1=1';
    push @ret, 'OR';
  }
  pop @ret;

  return \@ret if(@ret);
  return ['1=0'];

}

# most of this will be replaced by SQL::Interpolate
# make this work with table names
sub make_from_clause {

  my($self,$next,$vars) = @_;
  my $from = $vars->{from};
  my $columns = $vars->{columns};

  my @from = ();
  foreach my $subtable (ref $from eq 'ARRAY' ? @$from : $from) {

    foreach my $col (keys %$subtable) {
      my $tmp = $subtable->{$col};
      my @tmp = (ref $tmp eq 'ARRAY' ? @$tmp : $tmp);
      push @from, '(';
      push @from, map {
        ('SELECT', \$_, 'UNION ALL')
      } @tmp;
      push @from, ') as', $columns->{$col} || $col, 'JOIN' if('(' ne pop @from);
    }
    pop @from;
    push @from, 'UNION ALL' if(scalar %$subtable);

  }
  pop @from;

  return \@from;

}

42;

__DATA__

=head1 NAME

Class::Classless::DBI - provides a Classless object-oriented database interface

=head1 SYNOPSIS

  use DBI;
  use DBIx::Interpolate;
  use Class::Classless::DBI;

  my $dbh = DBI->connect(...);
  my $dbx = DBIx::Interpolate->new($dbh);

  my $dbo = $Class::Classless::DBI::ROOT->clone;
  $dbo->{METHODS}->{table} = 'table_name';
  $dbo->{METHODS}->{dbx} = $dbx;

  $dbo->insert_into_table(
    {
      values => [
        {col1 => 'A', col2 => 'B', col3 => 'C'},
        {col1 => 'a', col2 => 'b', col3 => 'c'},
        {col1 => '1', col2 => '2', col3 => '3'}
      ]
    }
  );

  $dbo->update_table(
    {
      values => {col1 => 'i', col2 => 'ii'},
      where   => {col1 => '1'}
    }
  );

  $dbo->delete_from_table(
    {
      where => {col3 => [qw(C c)]}
    }
  );

  $dbo->select_from_table();        # [{col1 => 'i', col2 => 'ii', col3 => '3'}]

=head1 DESCRIPTION

This module provides basic methods for classless objects to make database calls.
It is designed to use L<DBIx::Interpolate>, so future changes to that module are
likely to affect this module as well.

=head1 METHODS

=head2 C<delete_from_table>

=head2 C<insert_into_table>

=head2 C<select_from_table>

=head2 C<update_table>

These methods do what you would expect them to do. Each method can accept a
hashref as its argument. The following keys are used by these methods.

Note: C<select_from_table> returns an arrayref of hashrefs. All other methods
return the same information as C<&DBI::do>.

=head3 columns

The value of this key should be a hashref. It allows you to use a key other than
the column name when specifying table entries. For instance, the following two
queries are equivalent.

  $dbo->select_from_table(
    {
      where => {id => 5, val => 6}
    }
  );

  $dbo->select_from_table(
    {
      where => {foo => 5, val => 6},
      columns => {foo => 'id'}
    }
  );

This key applies to the values key for C<insert_into_table> and the where key
for the other methods.

=head3 group

This key applies only to C<select_from_table>. Its value should be an arrayref
containing the names of columns by which to group results.

=head3 values

This key applies to the methods C<insert_into_table> and C<update_table>. Its
value should be a hashref containing (column_name => value) entries. For
C<insert_into_table> it may also be an arrayref containing several hashrefs. In
that case, each hashref must contain the same number of columns. Column values
may also be arrayrefs, in which case a row will be inserted for each element of
the referenced array.

=head3 select

This key applies only to C<select_from_table>. Its value should be an arrayref
containing the names of columns to select from the table.

=head3 where

This key applies to all methods but C<insert_into_table>. Its value should be a
hashref or an arrayref containing hashrefs. Each hashref should contain
(column_name => value) entries that should all be satisfied for one row. An
empty hashref will match all rows. All rows that match any of the hashrefs
will be used. If the arrayref is empty, then no rows will be matched. However,
if where is undefined, all rows will be matched. In order to simplify some
queries, column values may also be arrayrefs, in which case rows that match any
element of the referenced array will be used. For example, the following two
queries are identical.

  $dbo->select_from_table(
    {
      where => [
        {id => 5, val => 6},
        {id => 5, val => 7},
        {id => 6, val => 6},
        {id => 6, val => 7}
      ]
    }
  );

  $dbo->select_from_table(
    {
      where => {id => [5,6], val => [6,7]}
    }
  );

=head2 C<make_where_clause>

=head2 C<make_from_clause>

These methods are used internally by the previous methods but are also available
for public use. They generate fragments of SQL queries to be used with
L<SQL::Interpolate>. C<make_where_clause> expects the where key to be present in
the same format as specified above. C<make_from_clause> expects a key named from
in the same format as values in a C<insert_into_table> method call. Both accept
the columns key as well.

=head1 AUTHOR

Mark Tiefenbruck <mdash@cpan.org>

=head1 LEGAL STUFF

Copyright (c) 2005, Mark Tiefenbruck. All rights reserved. This module is free
software. It may be used, redistributed and/or modified under the same terms as
Perl itself.

=head1 SEE ALSO

  L<Class::Classless>
  L<DBIx::Interpolate>
  L<Class::DBI>
