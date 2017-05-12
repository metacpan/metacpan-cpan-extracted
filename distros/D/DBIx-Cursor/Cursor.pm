########################################################################
#
#    Copyright (c) 2001,2002 by Tommi Mäkitalo
#
#    This package is free software; you can redistribute it
#    and/or modify it under the same terms as Perl itself.
#
########################################################################

package DBIx::Cursor;

use 5.6.0;
use strict;
use warnings;
use Carp;

our $VERSION = '0.14';

my %cache;

# ----------------------------------------------------------------------
sub new
{
  shift;
  my $self  = {};
  my $dbh   = shift;
  my $table = shift;
  my $pk    = \@_;

  # read names and types of columns
  unless ($cache{$table})
  {
    my $sth = $dbh->prepare("select * from $table where 0=1");
    $sth->execute or croak('error fetching columns');

    $self->{NAME}    = $sth->{NAME};
    $self->{TYPE}    = $sth->{TYPE};
    $self->{type}    = {};
    for (my $i = 0; $i < @{$self->{NAME}}; ++$i)
    {
      $self->{type}{$self->{NAME}[$i]} = $self->{TYPE}[$i];
    }

    # read primary-key if not given
    unless ($pk)
    {
      my @pk = $dbh->primary_key(undef, undef, $table);
      if (@pk)
      {
        $pk = \@pk;
      }
      else
      {
        croak ('primary key not known');
      }
    }

    $self->{pk}    = $pk;

    $cache{$table} = [$self->{NAME}, $self->{TYPE}, $self->{type}, $self->{pk}];
  }
  else
  {
    ($self->{NAME}, $self->{TYPE}, $self->{type}, $self->{pk}) = @{$cache{$table}};
  }

  # initialize values
  $self->{dbh}   = $dbh;
  $self->{table} = $table;

  # initialize data
  $self->{data}    = {};
  $self->{olddata} = {};

  # return value
  bless $self;
  return $self;
}

# ----------------------------------------------------------------------
sub DESTROY
{
  my $self = shift;
  $self->reset;
}

# ----------------------------------------------------------------------
sub dbh
{
  my $self = shift;
  return $self->{dbh};
}

# ----------------------------------------------------------------------
sub get_type
{
  my $self = shift;
  my $colname = shift;

  return $self->{type}{$colname} or croak ("column $colname not found");
}

# ----------------------------------------------------------------------
sub get_columns
{
  my $self = shift;
  return @{$self->{NAME}};
}

# ----------------------------------------------------------------------
sub read
{
  my $self = shift;
  my @values = @_;

  my @pk = @{$self->{pk}};

  croak ('invalid number of parameters') unless @values == @pk;

  my $dbh   = $self->{dbh};
  my $table = $self->{table};

  my $sth = $self->{sth_select};
  unless ($sth)
  {
    my $sql = "select * from $table where "
            . join(' and ', map { "$_ = ?" } @pk);

    $self->reset;
    $sth = $self->{sth_select} = $dbh->prepare($sql);
  }
  $sth->execute(@values);

  if ($self->{data} = $sth->fetchrow_hashref)
  {
    %{$self->{olddata}} = %{$self->{data}};
    return $self;
  }
  else
  {
    return undef;
  }
}

# ----------------------------------------------------------------------
sub set
{
  my $self = shift;
  my %newval = @_;

  while (my ($key, $value) = each (%newval) )
  {
    croak("column $key not found") unless $self->{type}{$key};
    $self->{data}{$key} = $value;
  }

  return $self;
}

# ----------------------------------------------------------------------
sub get
{
  my $self = shift;
  my @columns = @_;

  if (@columns)
  {
    if (wantarray)
    {
      return map { $self->{data}{$_} } @columns;
    }
    else
    {
      return $self->{data}{$columns[0]};
    }
  }
  elsif (wantarray)
  {
    return %{$self->{data}};
  }
  else
  {
    return $self->{data};
  }
}

# ----------------------------------------------------------------------
sub reset
{
  my $self = shift;

  $self->{data}    = {};
  $self->{olddata} = {};

  if ($self->{sth})
  {
    $self->{sth}->finish;
    $self->{sth} = undef;
  }

  return $self;
}

# ----------------------------------------------------------------------
sub where
{
  my $self = shift;

  $self->reset;
  $self->{where} = shift;
  $self->{values} = \@_;

  return $self;
}

# ----------------------------------------------------------------------
sub values
{
  my $self = shift;

  $self->reset;
  $self->{values} = \@_;

  return $self;
}

# ----------------------------------------------------------------------
sub fetch
{
  my $self = shift;

  unless ($self->{sth})
  {
    my $table = $self->{table};
    my $dbh   = $self->{dbh};
    my $sql   = "select * from $table";
    my $where = $self->{where};

    if ($where)
    {
      $sql .= ' where' if ($where !~ /^\s*(where)|(order\s+by)\s/i);
      $sql .= " $where";
    }

    my @values = @{$self->{values}} if $self->{values};
    $self->{sth} = $dbh->prepare($sql);
    $self->{sth}->execute(@values);
  }

  if ($self->{data} = $self->{sth}->fetchrow_hashref)
  {
    %{$self->{olddata}} = %{$self->{data}};
    return $self->get;
  }
  else
  {
    $self->reset;
    return undef;
  }
}

# ----------------------------------------------------------------------
sub update
{
  my $self = shift;

  my $data  = $self->{data};
  my $odata = $self->{olddata};
  my $table = $self->{table};
  my $dbh   = $self->{dbh};
  my $pk    = $self->{pk};

  # the columns to update are either given as parameter or
  # every not primary-key-column
  my @updatecols = @_ ? @_
                      : grep {                       # seach columns
                               my $col = $_;
                               # return every column not in primary-key
                               ! grep { $col eq $_ } @$pk
                             } @{$self->{NAME}};

  # check if update is needed
  my @cols;
  my @values;
  foreach my $col (@updatecols)
  {
    my $d = $data->{$col};
    my $o = $odata->{$col};
    next unless defined $d && !defined $o
       || !defined $d && defined $o
       || defined $d && defined $o && $o ne $d;
    push @cols, $col;
    push @values, $d;
  }

  return unless @cols;

  my $sql = "update $table set "
          . join(', ', map { "$_ = ?" } @cols )
          . ' where '
          . join(' and ', map { "$_ = ?" } @$pk);

  my @pkvalues = map { $odata->{$_} || $data->{$_} } @$pk;

  my $sth = $dbh->prepare($sql);
  my $ret = $sth->execute(@values, @pkvalues);
  %{$self->{olddata}} = %{$self->{data}};
  return $ret;
}

# ----------------------------------------------------------------------
sub insert
{
  my $self  = shift;
  my $table = $self->{table};
  my $dbh   = $self->{dbh};

  my $sth = $self->{sth_insert};
  unless ($sth)
  {
    my $sql = "insert into $table values ("
            . join(', ', ('?') x @{$self->{NAME}})
            . ')';

    $sth = $self->{sth_insert} = $dbh->prepare($sql);
  }

  my @values = map { $self->{data}{$_} } @{$self->{NAME}};

  return $sth->execute(@values);
}

# ----------------------------------------------------------------------
sub replace
{
  my $self = shift;
  return $self->update != 0 || $self->insert;
}

# ----------------------------------------------------------------------
sub delete
{
  my $self = shift;

  my $data  = $self->{data};
  my $table = $self->{table};
  my $dbh   = $self->{dbh};
  my $pk    = $self->{pk};

  my $sth = $self->{sth_delete};
  unless ($sth)
  {
    my $sql = "delete from $table where "
            . join(' and ', map { "$_ = ?" } @$pk);
    $sth = $self->{sth_delete} = $dbh->prepare($sql);
  }

  my @pkvalues = map { $data->{$_} } @$pk;

  $sth->execute(@pkvalues);
}

1;

__END__

=head1 NAME

DBIx::Cursor - Perl extension for easy DBI-access to a single table.

=head1 SYNOPSIS

  use DBIx::Cursor;
  my $c = new DBIx::Cursor($dbh, 'person', 'per_pid');

  while (my $r = $t->fetch)
  { printf "%s %s\n", $r->{per_firstname}, $r->{per_name}; }

  $c->read(1);

  $c->where('per_pid = 1 order by per_name');
  $c->fetch
  $c->set(per_firstname => 'Larry', per_name => 'Wall')
  $c->update;

  $c->reset
  $c->set(per_pid => 5, per_firstname => 'Linus', per_name => 'Torvalds')
  $c->insert;


=head1 DESCRIPTION

The class DBIx::Cursor represents a cursor for a single Database-table.
You can select, update, insert or delete entries in a table easier than
creating SQL-statements. It does not use any specific features of any
database, so it should work with every DBD-driver.

DBIx::Cursor is not a replacement for DBI, but a add-on. You can use
DBI as usual and use SQL-statements as you need.

=head1 METHODS

=head2 new

  my $c = new DBIx::Cursor($dbh, $table, $pk1, $pk2, ...)

The method new creates an instance of DBIx::Cursor. It returns a object,
which represents a table in the database. It checks, that the table
exists, so if you create a cursor for a not existing table, it will
die.

C<$dbh> is your connection-handle, you get from DBI.

C<$table> is the tablename, you want to use.

The remaining parameters are the names of your primary key. You can
use some alternate unique index as well.  

But be aware, that DBIx::Cursor does not check, if the index is ok.
It expects, that these columns identify exactly one row.

If you don't provide a key, DBIx::Cursor tries to get one through
the $dbh->primary_key-method. But not every driver support this
method, so to be compatible you should not use this feature.
DBD::Pg, which I use for testing, does not provide one.

=head2 dbh

Returns the databasehandle

=head2 get_type

  $c->get_type('col1');

Returns the type of the column. Refer to DBI-documentation and your driver for Columntypes

=head2 get_columns

Returns the columns of the table as an array.

=head2 read

  $c->read($value_of_pk1, $value_of_pk2, ...)

Fetches a row into the Cursor through the primary key.

You have to give him a value for every primary key column.

Returns the object itself on success or C<undef> when not found.

=head2 set

  $c->set(col1 => 'value 1', col2 => 'value 2', ...);

Sets the values of the named columns.

The Method dies if you give values for not existing columns.

The Values are not updated in the database.

=head2 get

  my $value1 = $c->get('col1');
  my @values = $c->get('col1', 'col2');
  my $values = $c->get;         # get hash-reference
  my %values = $c->get;

C<get> returns values for each column you request or a hash of all
columns it holds.

In scalar-context with one parameter it returns the value.

In array-context with one or more parameters it returns a array of the
values.

In array-context without parameters it returns a hash of key-value-pairs.

In scalar-context without parameters it returns a hash-reference of the
internel hash. You can modify the values of the hash if you need to.

The Method does not check, if the requested columns exist. It just returns
C<undef> for unknown values.

=head2 reset

  $c->reset

Clears the content of the cursor.

It returs the used DBIx::Cursor-object itself.

=head2 where

  $c->where('per_name like \'M%\' order by per_firstname');
  $c->where('per_firstname = ?', $name);

The where method sets a filter for retrieving rows. The string is directly
passed to the driver when needed. You can every SQL-feature you want.

You can also use the placeholder '?' and pass the values as additional
parameters. You don't need to give values here for these. You can later
pass or modify the values with the C<values>-Method.

The parameters aren't checked here. If the expression is not valid you get an
error if you try to C<fetch> the values.

The Cursor is C<reset>ed, so you get a fresh start on next C<fetch>.

The condition is actually appended to the SQL-statement:

  select * from table where

If the condition starts with 'where' or 'order by' the where is left out.
You can fetch all values from a table in a specific order with:

  $c->where('order by per_firstname')

It returs the used DBIx::Cursor-object itself.

=head2 values

  $c->values($name);

Set the values of the placeholders you passed with C<where>.

=head2 fetch

  $c->fetch

Do the actual fetch to the database. On the first call (or after resetting
the cursor) it builds the SQL-select statement and fetches the first row.
On subsequent calls it uses the statement and fetches subsequent rows.

It returns the fetched data as a hash-reference or - in array-context -
the hash or C<undef> when there is no more data availible.

=head2 update

  $c->update;
  $c->update('col1', 'col2');

Updates the record in the database to match the internal record.

It returns the number of updated records (should be 1, but this isn't
checked).

You can pass the column-names you want to update. By default every
not primary key column is updated.

If you want to update your primary key also, you can fetch the
row, modify your key and call C<$c->update($c->get_columns)>.

The method does no commit.

=head2 insert

  $c->insert;

Inserts a new Record with the values set.

Returns whatever DBI::execute returns.

=head2 replace

  $c->replace;

Tries to update data. If no record with the primary key set is found,
does a insert.

Returns whatever DBI::execute returns.

=head2 delete

  $c->delete

Deletes the record, which matches the primary key set.

=head1 AUTHOR

Tommi Mäkitalo, Dr. Eckhardt + Partner GmbH, E<lt>tommi@maekitalo.deE<gt>

=head1 COPYRIGHT

Copyright (c) 2001 by Tommi Mäkitalo, Dr. Eckhardt + Partner GmbH

=head1 LICENSE

This package is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

DBI

L<perl>.

=cut
