package DBIx::DBSchema::DBD;

use strict;

our $VERSION = '0.08';

=head1 NAME

DBIx::DBSchema::DBD - DBIx::DBSchema Driver Writer's Guide and Base Class

=head1 SYNOPSIS

  perldoc DBIx::DBSchema::DBD

  package DBIx::DBSchema::DBD::FooBase
  use DBIx::DBSchema::DBD;
  @ISA = qw(DBIx::DBSchema::DBD);

=head1 DESCRIPTION

Drivers should be named DBIx::DBSchema::DBD::DatabaseName, where DatabaseName
is the same as the DBD:: driver for this database.  Drivers should implement the
following class methods:

=over 4

=item columns CLASS DBI_DBH TABLE

Given an active DBI database handle, return a listref of listrefs (see
L<perllol>), each containing six elements: column name, column type,
nullability, column length, column default, and a field reserved for
driver-specific use.

=item column CLASS DBI_DBH TABLE COLUMN

Same as B<columns> above, except return the listref for a single column.  You
can inherit from DBIx::DBSchema::DBD to provide this function.

=cut

sub column {
  my($proto, $dbh, $table, $column) = @_;
  #@a = grep { $_->[0] eq $column } @{ $proto->columns( $dbh, $table ) };
  #$a[0];
  @{ [
    grep { $_->[0] eq $column } @{ $proto->columns( $dbh, $table ) }
  ] }[0]; #force list context on grep, return scalar of first element
}

=item primary_key CLASS DBI_DBH TABLE

Given an active DBI database handle, return the primary key for the specified
table.

=item unique CLASS DBI_DBH TABLE

Deprecated method - see the B<indices> method for new drivers.

Given an active DBI database handle, return a hashref of unique indices.  The
keys of the hashref are index names, and the values are arrayrefs which point
a list of column names for each.  See L<perldsc/"HASHES OF LISTS"> and
L<DBIx::DBSchema::Index>.

=item index CLASS DBI_DBH TABLE

Deprecated method - see the B<indices> method for new drivers.

Given an active DBI database handle, return a hashref of (non-unique) indices.
The keys of the hashref are index names, and the values are arrayrefs which
point a list of column names for each.  See L<perldsc/"HASHES OF LISTS"> and
L<DBIx::DBSchema::Index>.

=item indices CLASS DBI_DBH TABLE

Given an active DBI database handle, return a hashref of all indices, both
unique and non-unique.  The keys of the hashref are index names, and the values
are again hashrefs with the following keys:

=over 8

=item name - Index name (redundant)

=item using - Optional index method

=item unique - Boolean indicating whether or not this is a unique index

=item columns - List reference of column names (or expressions)

=back

(See L<FS::DBIx::DBSchema::Index>)

New drivers are advised to implement this method, and existing drivers are
advised to (eventually) provide this method instead of B<index> and B<unique>.

For backwards-compatibility with current drivers, the base DBIx::DBSchema::DBD
class provides an B<indices> method which uses the old B<index> and B<unique>
methods to provide this data.

=cut

sub indices {
  #my($proto, $dbh, $table) = @_;
  my($proto, @param) = @_;

  my $unique_hr = $proto->unique( @param );
  my $index_hr  = $proto->index(  @param );

  scalar(
    {
  
      (
        map {
              $_ => { 'name'    => $_,
                      'unique'  => 1,
                      'columns' => $unique_hr->{$_},
                    },
            }
            keys %$unique_hr
      ),
  
      (
        map {
              $_ => { 'name'    => $_,
                      'unique'  => 0,
                      'columns' => $index_hr->{$_},
                    },
            }
            keys %$index_hr
      ),
  
    }
  );
}

=item default_db_catalog

Returns the default database catalog for the DBI table_info command.
Inheriting from DBIx::DBSchema::DBD will provide the default empty string.

=cut

sub default_db_catalog { ''; }

=item default_db_schema

Returns the default database schema for the DBI table_info command.
Inheriting from DBIx::DBSchema::DBD will provide the default empty string.

=cut

sub default_db_schema { ''; }

=item constraints CLASS DBI_DBH TABLE

Given an active DBI database handle, return the constraints (currently, foreign
keys) for the specified table, as a list of hash references.

Each hash reference has the following keys:

=over 8

=item constraint - contraint name

=item columns - List refrence of column names

=item table - Foreign taable name

=item references - List reference of column names in foreign table

=item match - 

=item on_delete - 

=item on_update -

=back

=cut

sub constraints { (); }

=item column_callback DBH TABLE_NAME COLUMN_OBJ

Optional callback for driver-specific overrides to SQL column definitions.

Should return a hash reference, empty for no action, or with one or more of
the following keys defined:

effective_type - Optional type override used during column creation.

explicit_null - Set true to have the column definition declare NULL columns explicitly

effective_default - Optional default override used during column creation.

effective_local - Optional local override used during column creation.


=cut

sub column_callback { {}; }

=item add_column_callback DBH TABLE_NAME COLUMN_OBJ

Optional callback for additional SQL statments to be called when adding columns
to an existing table.

Should return a hash reference, empty for no action, or with one or more of
the following keys defined:

effective_type - Optional type override used during column creation.

effective_null - Optional nullability override used during column creation.

sql_after - Array reference of SQL statements to be executed after the column is added.

=cut

sub add_column_callback { {}; }

=item alter_column_callback DBH TABLE_NAME OLD_COLUMN_OBJ NEW_COLUMN_OBJ

Optional callback for overriding the SQL statments to be called when altering
columns to an existing table.

Should return a hash reference, empty for no action, or with one or more of
the following keys defined:

sql_alter - Alter SQL statement(s) for changing everything about a column.  Specifying this overrides processing of individual changes (type, nullability, default, etc.).

sql_alter_type - Alter SQL statement(s) for changing type and length (there is no default).

sql_alter_null - Alter SQL statement(s) for changing nullability to be used instead of the default.

=cut

sub alter_column_callback { {}; }

=item column_value_needs_quoting COLUMN_OBJ

Optional callback for determining if a column's default value require quoting.
Returns true if it does, false otherwise.

=cut

sub column_value_needs_quoting {
  my($proto, $col) = @_;
  my $class = ref($proto) || $proto;
 
  # type mapping
  my %typemap = eval "\%${class}::typemap";
  my $type = defined( $typemap{uc($col->type)} )
               ? $typemap{uc($col->type)}
               : $col->type;

  # false laziness: nicked from FS::Record::_quote
  $col->default !~ /^\-?\d+(\.\d+)?$/
    ||    $type =~ /(char|binary|blob|text)$/i;

}

=back

=head1 TYPE MAPPING

You can define a %typemap array for your driver to map "standard" data    
types to database-specific types.  For example, the MySQL TIMESTAMP field
has non-standard auto-updating semantics; the MySQL DATETIME type is 
what other databases and the ODBC standard call TIMESTAMP, so one of the   
entries in the MySQL %typemap is:

  'TIMESTAMP' => 'DATETIME',

Another example is the Pg %typemap which maps the standard types BLOB and
LONG VARBINARY to the Pg-specific BYTEA:

  'BLOB' => 'BYTEA',
  'LONG VARBINARY' => 'BYTEA',

Make sure you use all uppercase-keys.

=head1 AUTHOR

Ivan Kohler <ivan-dbix-dbschema@420.am>

=head1 COPYRIGHT

Copyright (c) 2000-2005 Ivan Kohler
Copyright (c) 2007-2013 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

=head1 SEE ALSO

L<DBIx::DBSchema>, L<DBIx::DBSchema::DBD::mysql>, L<DBIx::DBSchema::DBD::Pg>,
L<DBIx::DBSchema::Index>, L<DBI>, L<DBI::DBD>, L<perllol>,
L<perldsc/"HASHES OF LISTS">

=cut 

1;

