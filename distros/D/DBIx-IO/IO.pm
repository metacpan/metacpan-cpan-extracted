#
# $Id: IO.pm,v 1.2 2002/05/24 10:31:42 rsandberg Exp $
#

package DBIx::IO;

use strict;

use DBIx::IO::GenLib ();

use vars qw($VERSION);

$VERSION = '1.07';

=head1 NAME

DBIx::IO - Abstraction layer for database I/O with auto-discovery of data dictionary.

=head1 INTRODUCTION

Why yet another database abstraction layer module (DBAL)?
I wrote this before there were any popular abstraction layers on top of DBI available, when DBI itself was just becoming
popular. Therefore, I have taken a different approach than the others (Class::DBI and DBIx::Class, etc),
providing a set of distinct advantages that are more fitting for some applications.
This has been in use for many years at several production
sites and I still use it for new projects so hopefully it will be useful to others.

Perhaps the most important advantage/distinction DBIx::IO has is auto-discovery of the data dictionary.
Compare to Class::DBI and successors where the dictionary information must be duplicated in sub-classes.
With auto-discovery there is less code to write/maintain and your DBA can make
structural changes that will be immediately recognized. This avoids the hassle of keeping two data sources in sync.

See Cruddy! for a quick-start and example implementation:

L<http://www.thesmbexchange.com/cruddy/index.html>

Other advantages include:

=over

=item *

convenient date format handling and the ability to gracefully handle loose
date formats on input (very convenient for user interfaces)

=item *

driver-specific SQL hints

=item *

triggers

=item *

DBIx::IO::Search supports hierarchical queries (START WITH ... CONNECT BY ...)

=back


Briefly, some advantages of using a DBAL in general:

=over

=item *

Reduce embedded SQL in code

=item *

Consistent error handling (although using exceptions can be consistent as well)

=item *

Less mess with datatype mapping to/from the db (especially date handling)

=item *

Freedom of choice for your RDBMS and ease of migration if needed

=item *

Code re-use among different RDBMS's. Agreed that facilitating portability is nice but not always practical, one major point Jeremy Zawodny misses in
L<http://jeremy.zawodny.com/blog/archives/002194.html> is that DBAL's allow you to write code for an application
that uses one RDBMS and then reuse that code for another RDBMS

=back

Disadvantages include loss of flexibility for RDBMS-specific features, performance knobs, etc, though this can be somewhat
accommodated in thoughtful design of your RDBMS-specific adapter.

=head2 Relationships

This module has limited ability for defining relationships vs Class::DBI, etc.
DBIx::IO::Mask allows simple meta-data relationships to be defined for the convenience of mapping
human-readable to machine-efficient indentifiers (lookup tables). Anything more complex requires defining a view for SELECT's or overriding
methods to INSERT or UPDATE related records. While the relationship definition features present in DBIx::Class et al can save some coding, they have limitations as well and
those authors offer the very same suggestions (using views and overriding methods) for
anything complex.

=head2 RDBMS Support

Adapters for Oracle and MySQL are stable - for others, volunteers are welcome (please contact me).

=head2 Best Practices

Sound database design is key - starting with a solid yet flexible schema, and leveraging SQL (views, user-defined functions with PL/SQL, etc) can save months of coding and ongoing maintenance.
There are a few shortcuts within this library you can take advantage of if you use suggested naming conventions (see DBIx::IO::Table, DBIx::IO::Mask, etc).
Briefly, for a given table PARENT_TABLE, a field named PARENT_TABLE.PARENT_TABLE_ID will be assumed the primary key; for
a related table CHILD_TABLE, the column CHILD_TABLE.PARENT_TABLE_ID will be assumed a foreign key with a
primary key in PARENT_TABLE.PARENT_TABLE_ID. An analagous relationship exists for CHILD_TABLE.PARENT_TABLE and PARENT_TABLE.PARENT_TABLE
(same thing without the '_ID' appended). These assumptions can of course be overridden to fit your own best practices.

=head2 Next Steps

You probably won't ever use this module directly, from here you should probably review DBIx::IO::Table and DBIx::IO::Search. Enjoy!


=head1 SYNOPSIS

 use DBIx::IO;

Virtual base class - you won't use this module directly.

=head2 Methods

 $io = new DBIx::IO($dbh,$table_name,[$key_name]);


 $qualified_value = $io->qualify($value,[$column_name],[$date_format],[$datatype]);

 $datatype = $io->column_type($field_name);

 $integer = $io->field_length($field_name);

 $bool = $io->required($field_name);

 $default_value = $io->default_value($field_name);

 $rv = $io->verify_datatype($value,[$field_name],[$type]);

 $row = $io->fetch($id_val_or_id_hash,[$key_name]);

 $rv = $io->delete_by_id($id_value,[$key_name]);

 $rv = $io->delete_all($id_hash);

 $rv = $io->update_hash($update_hash,$id_val_or_id_hash,[$date_format],[$hint]);

 $rv = $io->insert_hash($insert_hash,[$date_format]);

 $sth = $io->make_cursor($query_sql);

 $next_id_val = $io->next_id([$table_name]);

 $column_types = $io->column_types();

=head2 Attribute Accessors/Modifiers

Get the values of these READ-ONLY attributes.

 $table_name    = $io->table_name();
 $dbh           = $io->dbh();

 $key_name      = $io->key_name();
May return undef if multi-part key.


=head1 DESCRIPTION

Methods are provided to perform basic database I/O via DBI without having to embed SQL in your programs. Records are normally passed in and out
in the form of hash references where keys of the hash represent columns (ALWAYS UPPER CASE), and the values are the corresponding column values.
For inserts, the primary key is usually auto-generated, assuming a few obvious conditions are met (DWIM, see insert()).
See DBIx::IO::GenLib for a discussion of the canonical date format, which will be used by default throughout these methods.
Bind variables are generally not used so, for performance reasons, you may be better off NOT using these methods if favor of bind variables if high
volumes of db IO will occur.

Virtual base class - must be subclassed by RDBMS-specific driver module. Please see driver-specific subclasses for details on many methods.

=head2 Messages and Logging

Warnings are handled similar to DBI, specifically, if the PrintError attribute is set
in the db handle, errors/warnings will be displayed (PrintError is set by default).

=head1 METHOD DETAILS

=over 4

=item C<new> (constructor)

 $io = new DBIx::IO($dbh,$table_name,[$key_name]);

Create a new $io object for database I/O operations.
A valid DBI (or DBIAccess) database handle must be given.
$table_name must be given and its attributes and column names will be discovered
and saved with the object.
Return undef if unsuccessful or error.
Return 0 if $table_name doesn't exist.

MySQL users:
If your platform has case-sensitive table names (Linux/UNIX), do yourself a favor and set lower_case_table_names=1 in /etc/my.cnf
and always use lower case names for tables.

=cut

##at memory usage and performance:
##at could save a lot by combining 4 hashes of this object into 1
##at there are 4 hashes that all contain all column names - column_types,defaults,lengths,required
##at more efficient to have 1 hash where each value is a hash with the 4 keys listed above
##at also if I'm using Tie::IxHash I could get rid of the column name array
sub new
{
    my ($caller,$dbh,$table_name,$key_name) = @_;
    my $class = ref($caller) || $caller;
    
    ref($dbh) || (warn("\$dbh doesn't appear to be valid"), return undef);
    $dbh->{LongReadLen} = $DBIx::IO::GenLib::LONG_READ_LENGTH;
    
    defined($table_name) || (warn("\$table_name not defined"), return undef);
    my $self =  bless({},$class);
    $self->{dbh} = $dbh;

    my $rv;
    unless ($rv = $self->_assign_table_attrs($table_name,$key_name))
    {
        defined($rv) || warn("Could not get table attributes");
        return $rv;
    }
    
    return $self;
}

sub table_name
{
    my $self = shift;
    return $self->{table_name};
}

sub dbh
{
    my $self = shift;
    return $self->{dbh};
}

sub key_name
{
    my $self = shift;
    return $self->{key_name};
}

=pod

=item C<qualify>

 $qualified_value = $io->qualify($value,[$column_name],[$date_format],[$datatype]);

Qualify $value and make it digestible by the db engine, usually for updates or inserts when bind variables are not involved.
$column_name or $datatype must be given. If $column_name is given the column's datatype is
taken from the column types discovered in the constructor. Otherwise you must manually
specify $datatype.
See DBIx::IO::GenLib for a list of supported datatypes and corresponding constants that may be used for $datatype.

For character datatypes this method strips null "\0" characters because DBI sees these
characters as string terminators (a C standard).
If for some reason null chars are desirable, use bind variables.

For dates, the canonical date format is assumed (see DBIx::IO::GenLib)
unless $date_format is defined. If the date format is unknown or suspect, (e.g. dates entered by humans) assign
the constant $UNKNOWN_DATE_FORMAT to $date_format and the format will be discovered via DBIx::IO::GenLib::normalize_date()
(extremely convenient at the cost of performance).

If $value is undefined, $qualified_value will return as the string 'NULL').
Return undef if error.

See also insert_hash() and update_hash() for an implementation.

For performance considerations, refer to driver-specific docs for driver-specific implemented methods.

=cut

=pod

=item C<verify_datatype>

 $rv = $io->verify_datatype($value,[$field_name],[$type]);

NOTE: Use DBIx::IO::GenLib::normalize_date to verify dates.

Verify the datatype of $value. Mostly useful for numerical
values. $field_name or $type must be given.

Return 0 if a numeric type was required but not given.
Return -1 if a decimal was given and will be rounded to an integer.

mysql users:
Return -2 if a negative number was given for an unsigned integer type.

=cut

=pod

=item C<default_value>

 $default_value = $io->default_value($field_name);

Return the default value listed in the data dictionary
for $field_name.
See also column_types().

=cut
sub default_value
{
    my ($self,$field) = @_;
    return $self->{defaults}{uc($field)};
}


=pod

=item C<required>

 $bool = $io->required($field_name);

Return true if $field_name is listed as NOT NULL in the data dictionary.
See also column_types().

=cut
sub required
{
    my ($self,$field) = @_;
    return $self->{required}{uc($field)};
}


=pod

=item C<field_length>

 $integer = $io->field_length($field_name);

Return the maximum length of $field_name according to the data dictionary.
Length will be compensated for numbers with decimals, and sign.
See also column_types().

=cut
sub field_length
{
    my ($self,$field) = @_;
    return $self->{lengths}{uc($field)};
}

# private sub for constructor
# return 0 if no columns for $table could be found
# Return undef if an invalid key_name was passed in
# semi-virtual method (yay perl!) must be overridden to set attribute from data dictionary
##at should do away with the whole concept of $key_name and use $keys or equiv
sub _assign_table_attrs
{
    my ($self,$table_name,$key_name) = @_;
    my $ct;
    $self->{pk} = [];
    unless ($ct = $self->column_attrs($table_name))
    {
        return $ct;
    }
    my $kn;
    if (($kn = uc($key_name)))
    {
        exists($ct->{$kn}) || (warn("Key: $kn does not exist as a column in $table_name"),return undef);
    }
    elsif (@{$self->{pk}} == 1)
    {
        $kn = $self->{pk}[0];
    }
    else
    {
        undef($kn);
    }
    $self->{key_name} = $kn;
    $self->{table_name} = $table_name;
    return 1;
}


=pod

=item C<column_types>

 $column_types = $io->column_types();

Get the column names and associated data types for $table_name (can be given to the constructor).
The return value is a hash ref of column => datatype pairs.
By convention, column names are in UPPER CASE.
The column types are returned in UPPER CASE (not by convention, but
compatible with the data types defined for use with qualify())

The attributes are cached for each table requested for any object of this class
so the database may not be queried each time this method is called.

Oracle users:
If $table_name is a concrete table (rather than a view, for instance)
ROWID will be included as a column with ROWID datatype. You may find this
useful for updates and deletes (See also DBIx::IO::GenLib for a ROWID column name constant).

=cut
sub column_types
{
    my ($self) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    return $self->{column_types};
}

=pod

=item C<column_type>

 $datatype = $io->column_type($field_name);

Return the datatype of $field_name
See also column_types().

=cut
sub column_type
{
    my ($self,$field) = @_;
    return $self->{column_types}{uc($field)};
}

=pod

=item C<make_cursor>

 $sth = $io->make_cursor($query_sql);

Prepare and execute $query_sql and return the statement handle ($sth).
Error checking is done at each step. (This is useless however, if
the RaiseError db attribute is true)
Returns undef if error.

=cut
sub make_cursor
{
    my ($self,$sql) = @_;
    my $sth = $self->{dbh}->prepare($sql) || return undef;
    $sth->execute() || return undef;
    return $sth;
}

=pod

=item C<insert_hash>

 $rv = $io->insert_hash($insert_hash,[$date_format]);

Insert a row with name value pairs contained 
in $insert_hash. Values will be automatically qualified
according to column datatypes so don't pre-qualify them.
For date values, the canonical format is assumed
(see qualify()) unless $date_format is specified.

This method is useful because it automagically 
qualifies each insert value using qualify().
Also, if the table has an integral primary key,
and the corresponding key in $insert_hash was not given, a value
for will be generated.

MySQL users:
This assumes the primary key was declared with AUTO_INCREMENT, so no extra work is done
except to pass the newly generated value back in $rv.

Oracle users:
The situation described above assumes an Oracle sequence object named
SEQ_$table_name has been created. This is the conventional naming scheme so that this feature
can be taken advantage of in most cases. E.g., if inserting into table MEMBER, an associated
SEQUENCE object named SEQ_MEMBER must also exist. See C<DBIx::IO::OracleIO::sequence_name>.

In short, you generally don't have
to supply a table's primary key if that primary key is a sequenced ID column.

Return the generated pk ID value or -1.2 if there wasn't a value generated (e.g. if the table has a multi-column pk)
If there was no data to insert, -1.1 is returned.
Return undef if error.


=cut

=pod

=item C<fetch>

 $row = $io->fetch($id_val_or_id_hash,[$key_name]);

Return a row in hashref form (COLUMN_NAME => value pairs).
All date values are returned in the canonical format (see DBIx::IO::GenLib).

The row to be fetched is identified depending on the datatype of $id_val_or_id_hash.

If $id_val_or_id_hash is a scalar, the value is used in conjunction with $key_name.
$key_name defaults to the table's primary key.
If $id_val_or_id_hash is a hash ref it is interpreted as column => value
pairs to be AND'ed together in a WHERE clause.

This method assumes that key(s) given form a unique key, so only 1 row is returned.

Oracle users:
LOB columns won't be retreived because they aren't supported in DBD::Oracle (as of v1.19). LONG columns seem to work
fine though so if you can get away with using a LONG over a LOB, do that.
$DBIx::IO::GenLib::LONG_READ_LENGTH gives the limit size of a long that will be returned.
If the table is a concrete table (rather than a view, for instance)
ROWID will be included as a column with ROWID datatype. You may find this
useful for updates and deletes (See also DBIx::IO::GenLib for a ROWID column name constant).


Return undef if error.
Return 0 if no row was found.

=cut
sub fetch
{
    my ($self,$key,$key_name) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    my $table = $self->table_name();

    unless (ref($key))
    {
        $key_name = uc($key_name) || $self->key_name() || ($self->_alert("No key column name given"),return undef);
        exists($self->{column_types}->{$key_name}) || ($self->_alert("$key_name is not a column of $table, does $table have a multi-part key?"), return undef);
        $key = { $key_name => $key };
    }

    my $where = $self->_build_where_clause($key) || return undef;
    my $cols = $self->{select_cols};
    my $sth = $self->make_cursor("SELECT $cols FROM $table $where") || return undef;
    my $rv = $sth->fetchrow_hashref();
    $sth->err && ($self->_alert("Error fetching from $table $where"), return undef);
    # Safeguard so that we know %$rv evaluation won't cause a runtime error
    ref($rv) || return 0;
    return (%$rv ? $rv : 0);
}

=pod

=item C<delete_by_id>

 $rv = $io->delete_by_id($id_value,[$key_name]);

Delete a row where $key_name = $id_value.
$key_name defaults to the primary key.

Returns the number of rows deleted or false if error (0 is represented as '0E0' which is true).
A maximum of 1 row can be deleted here, it is up to you to make sure that the given
key is unique, otherwise unexpected results can occur. See also delete_all().

=cut
sub delete_by_id
{
    my ($self,$id_val,$key_name) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    my $table = $self->table_name();
    $key_name = uc($key_name) || $self->key_name() || ($self->_alert("No key column name given"),return undef);
    exists($self->{column_types}->{$key_name}) || ($self->_alert("$key_name is not a column of $table, does $table have a multi-part key?"), return undef);
    $id_val = $self->qualify($id_val,$key_name);
    unless (defined($id_val))
    {
        $self->_alert("Unable to qualify ID value: qualify($id_val,$key_name)");
        return undef;
    }
    my $sql = "DELETE FROM $table WHERE $key_name = $id_val";

    # limit the number of rows deleted.
    $self->limit($sql,1,'AND');
    my $dbh = $self->dbh();
    return $dbh->do($sql);
}


=pod

=item C<delete_all>

 $rv = delete_all($id_hash);

Delete all rows that satisfy $id_hash, where $id_hash
is a hash of COLUMN => value pairs that will be AND'ed together for the
WHERE clause of the DELETE statement.

Returns the number of rows affected or false if error (0 is represented as '0E0' which is true).
Return -1 if $id_hash is empty or not a reference.

=cut
sub delete_all
{
    my ($self,$id_hash) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    (ref($id_hash) && %$id_hash) || return -1;

    my $where = $self->_build_where_clause($id_hash) || return undef;
    my $dbh = $self->dbh();
    my $table = $self->table_name();
    return $dbh->do("DELETE FROM $table $where");
}

=pod

=item C<update_hash>

 $rv = $io->update_hash($update_hash,$id_val_or_id_hash,[$date_format],[$hint]);

Update a row with name value pairs contained 
in $update_hash, a hashref of COLUMN_NAME => new_value pairs.
Values will be automatically qualified
according to column datatypes so don't pre-qualify them.
For date values, the canonical format is assumed
unless $date_format is specified (see qualify()).

The row(s) to be updated are identified depending on the datatype of $id_val_or_id_hash.

If $id_val_or_id_hash is a scalar, the value is used as the primary key.
If $id_val_or_id_hash is a hash ref it is interpreted as COLUMN_NAME => value
pairs to be AND'ed together in a WHERE clause.

This method supports driver-specific SQL hints contained in $hint.

Return the number of rows affected or false if error (0 is represented as '0E0' which is true).
Return -1 if there was no data to update.

=cut

# warn if PrintError (from $dbh) flag is on.
sub _alert
{
    my ($self,$message) = @_;
    warn($message) if $self->{dbh}->{PrintError};
}

# return the argument with "_ID" appended
# argument is assumed to be a table_name and the return
# value is assumed to be the name of the table's pk.
sub _id_name
{
    my ($caller,$table) = @_;
    ($table) = $caller->_strip_owner($table);
    return uc($table) . "_ID";
}

sub _strip_owner
{
    my ($caller,$object) = @_;
    if ($object =~ /(.*)\.(.*)/)
    {
        return ($2,$1);
    }
    return ($object);
}

sub _build_where_clause
{
    my ($self,$keys) = @_;
    ref($keys) || ($self->_alert("\$keys not a hashref"), return undef);
    my ($col,$val);
    my $where = "WHERE ";
    while (($col,$val) = each %$keys)
    {
        $val = $self->qualify($val,$col);
        unless (defined($val))
        {
            $self->_alert("Unable to qualify ID value: qualify($val,$col)");
            return undef;
        }
        $where .= "$col = $val AND ";
    }
    chop $where;
    chop $where;
    chop $where;
    chop $where;

    return $where;
}

=pod

=back

=cut

1;

__END__

=head1 BUGS

No known bugs.

=head1 SEE ALSO

Driver specific subclasses C<DBIx::IO::<driver_name>IO>, L<DBIx::IO::Table>, L<DBIx::IO::Search>, L<DBIx::IO::Mask>, Cruddy! L<http://www.thesmbexchange.com/cruddy/index.html>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

