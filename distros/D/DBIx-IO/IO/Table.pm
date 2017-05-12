# Table.pm
#
# $Id: Table.pm,v 1.2 2002/05/24 10:33:05 rsandberg Exp $
#

package DBIx::IO::Table;

use strict;
use DBIx::IO::GenLib ();

=head1 NAME

DBIx::IO::Table - Objectified abstract of a database table


=head1 SYNOPSIS

 use DBIx::IO::Table;



 $table = DBIx::IO::Table->new($dbh,[$attrs_or_key_value],[$key_name],[$table_name]);
 
 $record = $table->fetch($id_val_or_id_hash);

 $record = $table->new_record();

 $record = $table->exist_record();

 $value = $table-><COLUMN_NAME>($value);        # set <COLUMN_NAME>

 $value = $table-><COLUMN_NAME>();              # get value of <COLUMN_NAME>

 $success = $table->delete();

 $rv = $table->delete_all($id_hash);

 $success = $table->update([$update],[$persist]);

 $pk = $table->insert([$insert],[$persist]);

 $success = $table->add_values($add_hash);

 $value = $table->single_column_lookup($column_name,$table_name,$key,$key_name);
 $value = DBIx::IO::Table->single_column_lookup($column_name,$table_name,$key,$key_name,$dbh);

 $datatype = $table->column_type($field_name);

 $integer = $table->field_length($field_name);

 $bool = $table->required($field_name);

 $default_value = $table->default_value($field_name);

 $rv = $table->verify_datatype($value,[$field_name],[$type]);

=head2 Attribute Accessors/Modifiers

=head3 Get the values of these READ-ONLY attributes.

 $table_name    = $table->name();
 $dbh           = $table->dbh();
 $io            = $table->io();
 $arrayref      = $table->pk();
 $key_name      = $table->key_name();
 $id_value      = $table->id();
 $table_columns = $table->column_types();

=head3 Get or set the values of these attributes.

 $persistence = $table->persist();
 $persistence = $table->persist($bool);


=head1 DESCRIPTION

This class is useful for handling db I/O for a particular table. You create
the object, associate a row with the object, then update, insert, view or delete
the corresponding record in the table. Qualifying the values is done automatically
according to column datatypes. All dates should be in the normalized format mentioned
in DBIx::IO::GenLib, which also contains helpful methods of getting dates in the
correct format.

The object potentially stores 2 records: exist_rec and new_rec. exist_rec is populated if an
existing record is fetched from the table. This also populates new_rec which can be
subsequently overwritten with the column setter methods. Before an update can occur, a fetch
must be performed so that exist_rec is populated; exist_rec never changes.
See also DBIx::IO.


=head2 Persistence

After insert() update() or delete() has been called, all data in exist_rec and new_rec will be
wiped out, use the persist() method if you want update() and insert() to fetch the new record
as it exists in the db for further use. (triggers and such can modify data after committing them).
Persistence can be set by calling persist(1).


=head2 Multi-part unique keys

See fetch().


=head2 Driver Specific

Each $table object has an $io object attribute constructed from the corresponding
driver specific DBIx::IO::XXXIO class. Consequently, DBIx::IO::Table can only support Oracle and MySQL as yet.
Use this object to manipulate driver-specific features.


=head2 Transactions

You are responsible for transaction control.


=head2 Implementation And Subclassing

Derived classes can have the
same name as the table they represent, this way DBIx::IO::Table can assume the
name of the table, primary key and other attributes (see the contructor for details).

Column accessor methods are automatically created using AUTOLOAD so that:
$table-><COLUMN_NAME>($value) will set <COLUMN_NAME> to $value,
$table-><COLUMN_NAME>() will return the value of <COLUMN_NAME> according to the
following rules:
The associated value from new_rec will be returned.
If a record has not been fetched and the value not previously set, undef
will be returned.

AUTOLOAD also creates a parallel set of methods for each column just before an update is done:
__update__<COLUMN_NAME>() These methods are called explicitly on each column just before an update
is finished, and allows for an audit trail or trigger. The individual column accessors ($table-><COLUMN_NAME>()) are also called explicitly for each column on the
bulk setters (e.g. using add_values() or by providing a hash upon construction or in the insert and update methods).
NOTE: For the individual setters a final action of update is assumed if a fetch was done previously,
(exist_rec is defined) otherwise a final action of insert is assumed.

=head2 Database trigger simulation

If your derived class wants to capture control before a particular value is set, override the
appropriate <COLUMN_NAME>() method in your subclass. If you want to
capture control before a particular column => value is committed to the db (for updates), 
override the corresponding __update__<COLUMN_NAME>() method.
By overridding these accessor methods you can effectively create
an interactive db trigger.
To clarify, <COLUMN_NAME>() methods are called to modify the object's record with the
intention of calling insert() or update(). Once update() is called, __update__<COLUMN_NAME>($new_value)
is invoked for each column and the associated operation is performed
and committed in the database.
CAUTION! not do initiate a commit directly or indirectly when overriding these methods.

Example:
For a table object that is updating STATUS, the class may
want to define a STATUS() function to force the user to enter a
comment for certain status changes. Also __update__STATUS()
can be defined to log the status change to a separate table.


=head1 Method Details


=over 4

=item C<new> (constructor)

 $table = DBIx::IO::Table->new($dbh,[$attrs_or_key_value],[$key_name],[$table_name]);

$dbh must be a valid db handle
created with DBI (or DBIAccess).

$key_name and $table_name can be given explicitly
or implied by the name of the derived class initiating this constructor. 
If these values are implied, $table_name becomes the name of the derived class
(less any XXX:: package qualifiers - I recommend the class name should be lower case) and $key_name = <table_name>_ID || <table_name> depending on which
corresponding column name exists in the table.
In either case, $key_name should be a unique key on $table_name.
See fetch() if you need to access a table with a multi-part unique key.

$attrs_or_key_value can be given in 1 of 2 datatypes:

1) If a scalar is given, it will be treated as a value of the
primary key column. The corresponding
record will be fetched and added to new_rec and exist_rec (described below).
NOTE: All objects need to retrieve a record either by this method or fetch()
(described elsewhere) before an update can occur.

2) If a reference is given it will be treated as a hashref of COLUMN_NAME => value
pairs that will be added to the object's new_rec (described below).

If all goes well, a new $table object is returned. If an error occurs, undef will be returned.
If the table doesn't exist, or $attrs_or_key_value is given as a scalar and
the corresponding row doesn't exist, 0 will be returned.

=item C<Column setter methods>

 $table-><COLUMN_NAME>('value') where <COLUMN_NAME> is a valid column in the table

To set a value to NULL (for updates), call the setter with '' as a value:
$table-><COLUMN_NAME>(''). This makes updating a value to NULL more explicit,
which is a good thing. If the empty string, '' is a desirable update value,
use $DBIx::IO::GenLib::EMPTY_STRING.

See also new(), update(), add_values() and insert() which take hashref's to set column values in bulk.

=item C<Column getter methods>

 $table-><COLUMN_NAME>() where <COLUMN_NAME> is a valid column in the table

Return undef if error.
Return '' if NULL.
Return $DBIx::IO::GenLib::EMPTY_STRING if the value is the empty string, ''.

See also:
 $table->exist_record()
 $table->new_record()

Note that these COLUMN_NAME methods are always in UPPER CASE.

=cut
##at note that for Oracle this will only work if $dbh is connected to the schema owner because you use select from USER_TABLES etc
sub new
{
    my ($caller,$dbh,$attrs_or_pk,$key_name,$table) = @_;
    my $class = ref($caller) || $caller;
    my $self =  bless({},$class);
    ref($dbh) || (warn("\$dbh doesn't appear to be valid"), return undef);
    eval{ $dbh->{FetchHashKeyName} = 'NAME_uc'; }; # If they have an older DBI just hope for the best?
    $table ||= $class;
    $table =~ s/.*:://;   # strip fully-qualified portion

    my $ioclass = $self->_pull_driver($dbh);
    return undef unless defined($ioclass);

    my $rv;
    unless ($rv = $ioclass->new($dbh,$table,$key_name))
    {
        return $rv;
    }
    $self->{io} = $rv;
    
    if (defined($attrs_or_pk) && ref($attrs_or_pk))
    {
        $self->add_values($attrs_or_pk) || (warn("Could not add values from \$attrs_or_key_value"), return undef);
    }
    elsif (defined($attrs_or_pk))
    {
        unless ($rv = $self->fetch($attrs_or_pk))
        {
            defined($rv) || (warn("Error fetching $attrs_or_pk"), return undef);
            return $rv;
        }
    }
    return $self;
}

sub _pull_driver
{
    my ($caller,$dbh) = @_;

    return $caller->{ioclass} if ref($caller) && defined($caller->{ioclass});

    # IO classes must be named after the DBI driver name!!
    my $ioclass = "DBIx::IO::$dbh->{Driver}{Name}IO";
    my $libclass = "DBIx::IO::$dbh->{Driver}{Name}Lib";
    eval qq(require $ioclass) || (warn("Database driver not supported"),return undef);
    if (eval qq(require $libclass))
    {
        #$caller->{norm_datetime_format} = eval("\$${libclass}::NORMAL_DATETIME_FORMAT") if ref($caller);
    }

    $caller->{ioclass} = $ioclass if ref($caller);
    return $ioclass;
}

##at could have a function normalize_all_dates() to facilitate use with unknown date formats.

=pod

=item C<single_column_lookup>

 $value = $table->single_column_lookup($column_name,$table_name,$key,$key_name);
 $value = DBIx::IO::Table->single_column_lookup($column_name,$table_name,$key,$key_name,$dbh);

Return "SELECT $column_name FROM $table_name WHERE $key_name = $key"
If called with a $table object then $table_name, $key_name and $dbh default to
those properties of $table.

Return undef if error.
Return '' if NULL.
Return $DBIx::IO::GenLib::EMPTY_STRING if the value is the empty string, ''.

=cut
sub single_column_lookup
{
    my ($caller,$column_name,$table_name,$key,$key_name,$dbh) = @_;
    if (ref($caller))
    {
        $table_name ||= $caller->name();
        $key_name ||= $caller->key_name();
        $dbh ||= $caller->dbh();
    }
    my $table = $caller->new($dbh,$key,$key_name,$table_name) ||
        (warn("Can't allocate table object for data: ($column_name,$table_name,$key,$key_name)"), return undef);
    my $rec = $table->exist_record();
    my $ret = $rec->{uc($column_name)};
    return (defined($ret) ? ($ret eq '' ? $DBIx::IO::GenLib::EMPTY_STRING : $ret) : ''); # return a defined value in any case
}

=pod

=item C<fetch>

 $record = $table->fetch($id_val_or_id_hash);

Return a row in hashref form (COLUMN_NAME => value pairs).
All date values are returned in the canonical format (see DBIx::IO::GenLib).

The row to be fetched is identified depending on the datatype of $id_val_or_id_hash.

If $id_val_or_id_hash is a scalar, the value is used in conjunction with the table's primary key.
If $id_val_or_id_hash is a hash ref it is interpreted as column => value
pairs to be AND'ed together in a WHERE clause.

This method assumes that key(s) given form a unique key, so only 1 row is returned.
The object's existing record is set for comparison when/if update() (described elsewhere) is called.
This routine overwrites all column attributes previously set by setting new_rec;
equivalent to creating a new object with a key value.

Oracle users:
LOB columns won't be retreived because they aren't supported in DBD::Oracle (as of v1.19). LONG columns seem to work
fine though so if you can get away with using a LONG over a LOB, do that.
$DBIx::IO::GenLib::LONG_READ_LENGTH gives the limit size of a LONG that will be returned.
If the table is a concrete table (rather than a view, for instance)
ROWID will be included as a column with ROWID datatype. You may find this
useful for updates and deletes (See also DBIx::IO::GenLib for a ROWID column name constant).


Return undef if error.
Return 0 if no row was found.

=cut
sub fetch
{
    my ($self,$key_val) = @_;
    my $row;
    unless ($row = $self->{io}->fetch($key_val))
    {
        return $row;
    }
    if (ref($key_val))
    {
        $self->{mult_id} = $key_val;
        $self->{fetch_key} = $key_val;
    }
    else
    {
        $self->{fetch_key} = { $self->key_name() => $key_val };
    }
    $self->{exist_rec} = { %$row };     # Make a copy of the hash
    $self->{new_rec} = { %$row };       # ''
    return $row;
}

=item C<Attribute Accessors/Modifiers>

=over 2

Get the values of these READ-ONLY attributes.
CAUTION: Don't modify these values - you've been warned.

 $table_name    = $table->name();
 $dbh           = $table->dbh();

May return undef if multi-part key (see also C<pk>).
 $key_name      = $table->key_name();

Return the underlying RDBMS-specific DBIx::IO driver.
 $io            = $table->io();

Return the value(s) of the primary key. Return a scalar if single-valued
or a hashref of COLUMN_NAME => value pairs if a multi-column key.
 $id_value      = $table->id();

Return an arrayref of the key column names from the $io object
 $key_arrayref   = $table->pk();

Return a hash of COLUMN_NAME => DATA_TYPE pairs.
 $table_columns = $table->column_types();


Get or set the values of these attributes.

 $persistence = $table->persist();
 $persistence = $table->persist($bool);

=back

=cut
sub column_types
{
    my $self = shift;
    return $self->{io}->column_types();
}

sub name
{
    my $self = shift;
    return $self->{io}->table_name();
}

sub dbh
{
    my $self = shift;
    return $self->{io}->dbh();
}

sub io
{
    my $self = shift;
    return $self->{io};
}

sub pk
{
    my ($self) = @_;
    return $self->{io}{pk};
}

sub key_name
{
    my $self = shift;
    return $self->{io}->key_name();
}

sub persist
{
    my ($self,$persist) = @_;
    if (defined($persist))
    {
        return $self->{persist} = ($persist ? 1 : 0);
    }
    return $self->{persist};
}

sub id
{
    my $self = shift;
    my $rec = $self->exist_record();
    return (defined($rec->{$self->key_name()}) ? $rec->{$self->key_name()} : $self->{mult_id});
}

=pod

=item C<new_record>

 $record = $table->new_record()

Returns the record built with column setter methods pending update or insert.
Values default to those of the existing record if a fetch() was done (see exist_record()).
Return false if no record was retrieved.

=cut
sub new_record
{
    my $self = shift;
    ref($self) || ($self->{io}->_alert("Method must be called by an object"), return undef);
    return (ref($self->{new_rec}) ? { %{$self->{new_rec}} } : undef);
}

=pod

=item C<exist_record>

 $record = $table->exist_record()
 
Returns the COLUMN_NAME => value pairs of the existing record which was originally retrieved
by the constructor or by calling fetch().
Return false if no record was retrieved.

=cut
sub exist_record
{
    my $self = shift;
    ref($self) || ($self->{io}->_alert("Method must be called by an object"), return undef);
    return (ref($self->{exist_rec}) ? { %{$self->{exist_rec}} } : undef);
}


# this prevents column names from being named DESTROY, also __update__XXX
sub DESTROY
{
}

# This generates all getters and setters for each column.
sub AUTOLOAD 
{
    my $self = shift;
    my ($new_val) = @_;
    ref($self) || ($self->{io}->_alert("$self is not an object"), return undef);

    my $name = $DBIx::IO::Table::AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    my $column_types = $self->column_types();
    if ($name =~ /__update__(.*)/)
    {
        exists($column_types->{$1}) || ($self->{io}->_alert("$1 is not a column of " . $self->name()), return undef);
        return shift;
    }
    
    exists($column_types->{$name}) || ($self->{io}->_alert("$name is not a column of " . $self->name()), return undef);

    if (defined($new_val))
    {
        return $self->{new_rec}{$name} = $new_val;
    } 
    else 
    {
        my $ret = $self->{new_rec}{$name};
        return (defined($ret) ? ($ret eq '' ? $DBIx::IO::GenLib::EMPTY_STRING : $ret) : '');
    }
}


=pod

=item C<delete>

 $success = $table->delete();

Delete $table's current record.
Its up to you to make sure that the current record was fetched via a
unique key, otherwise unexpected results can occur. See also delete_all().

Returns the number of rows deleted or false if error (0 is represented as '0E0' which is true).
Return -1 if there is no current record (no fetch() was done).

=cut
sub delete
{
    my ($self) = @_;
    my $rv = $self->{io}->delete_all($self->{fetch_key});
    unless ($rv)
    {
        return $rv;
    }
    delete $self->{exist_rec};
    delete $self->{new_rec};
    return $rv;
}

=pod

=item C<delete_all>

 $rv = $table->delete_all($id_hash);

Delete all rows that satisfy $id_hash, where $id_hash
is a hash of COLUMN_NAME => value pairs that will be AND'ed together for the
WHERE clause of the DELETE statement.

Returns the number of rows deleted or false if error (0 is represented as '0E0' which is true).
Return -1 if $id_hash is empty or not a reference.

=cut
sub delete_all
{
    my ($self,$id_hash) = @_;
    my $rv = $self->{io}->delete_all($id_hash);
    unless ($rv)
    {
        return $rv;
    }
    return $rv;
}

=pod

=item C<update>

 $success = $table->update([$update],[$persist])

Update the object's exist_rec to new_rec. If $update is defined, its
COLUMN_NAME => value pairs will be added to new_rec via add_values() (explained elsewhere).
$persist: if true, the updated record will be retrieved for further work,
otherwise this object's exist_rec and new_rec values will be undef'ed.

Only a delta of column values that differ between exist_rec and new_rec are updated.
__update__<COLUMN_NAME>($new_val) is called for each column in the delta.
Its up to you to make sure the current record was fetched via a
unique key, otherwise unexpected results can occur.

Return the number of rows updated or false if error (0 is represented as '0E0' which is true).
Return -1 if there was no data to update.
Return -2 if persistence is desired and the updated row could not be fetched.

=cut
sub update
{
    my ($self,$update,$persist) = @_;
    $self->add_values($update) || ($self->{io}->_alert("Can't add values from \$update"), return undef) if ref($update);
    my $delta;
    my $rt;
    unless ($delta = $self->_prepare_update())
    {
        return undef;
    }
    unless ($rt = $self->{io}->update_hash($delta,$self->{fetch_key}))
    {
        return undef;
    }
    my $id = $self->id();
    delete $self->{exist_rec};
    delete $self->{new_rec};
    $self->persist() || $persist || return $rt;
    $self->fetch($id) || return -2;
    return $rt;
}

sub _prepare_update
{
    my $self = shift;
    ref($self) || ($self->{io}->_alert("Method must be called by an object"), return undef);
    my $new_rec = $self->new_record() || {};
    my $exist_rec = $self->exist_record() || {};
    my $column_attrs = $self->column_types();
    my ($field,$new_val,%ret);
    while (($field,$new_val) = each %$new_rec)
    {
        # No attempt is made to find numerical equivalents because new_rec is set to exist_rec from fetch()
        if ($new_val ne $exist_rec->{$field})
        {
            defined(eval("\$self->__update__${field}(\$new_val)")) ||
                ($self->{io}->_alert("pre-update routine failed for $field: $new_val"), return undef);
            $ret{$field} = $new_val;
        }
    }
    return (\%ret);
}

=pod

=item C<insert>

 $pk = $table->insert([$insert],[$persist]);

Insert the current record, if $insert is defined, its
COLUMN_NAME => value pairs will be added via add_values() (explained elsewhere) before the insert.
$persist: if true, the inserted record will be retrieved for further work.
This only works if a key column was discovered in the constructor.
Otherwise this object's exist_record and new_record values will be undef'ed.

Return the generated pk ID value or -1.2 if there wasn't a value generated (e.g. if the table has a multi-column pk)
If there was no data to insert, -1.1 is returned.
Return -1.3 if persistence is desired and the new row could not be fetched.
Return -1.4 if a unique key violation occurred.
Return undef if error.

=cut
sub insert
{
    my ($self,$insert,$persist) = @_;
    $self->add_values($insert) || ($self->{io}->_alert("Can't add values from \$insert"), return undef) if ref($insert);
    $insert = $self->new_record() || {};
    my $pk = $self->{io}->insert_hash($insert);
    unless (defined($pk))
    {
        return undef;
    }
    delete $self->{exist_rec};
    delete $self->{new_rec};
    $self->persist() || $persist || return $pk;
    return $pk if $pk == -1.1;
    my $id;
    if ($pk == -1.2)
    {
        my $ps = $self->pk();
        foreach my $p (@$ps)
        {
            $id->{$p} = $insert->{$p};
        }
    }
    else
    {
        $id = $pk;
    }
    $self->fetch($id) || ($self->{io}->_alert("Can't fetch inserted record for persistence"), return -1.3);
    return $pk;
}

=pod

=item C<column_type>

 $datatype = $table->column_type($field_name);

Return the datatype of $field_name
See also DBIx::IO.

=cut
sub column_type
{
    my $self = shift;
    return $self->{io}->column_type(@_);
}

=item C<verify_datatype>

 $rv = $table->verify_datatype($value,[$field_name],[$type]);

NOTE: Use DBIx::IO::GenLib::normalize_date to verify dates.

Verify the datatype of $value. Mostly useful for numerical
values. $field_name or $type must be given.

Return 0 if a numeric type was required but not given.
Return -1 if a decimal was given and will be rounded to an integer.

mysql users:
Return -2 if a negative number was given for an unsigned integer type.

See also DBIx::IO.

=cut
sub verify_datatype
{
    my $self = shift;
    return $self->{io}->verify_datatype(@_);
}

=pod

=item C<default_value>

 $default_value = $table->default_value($field_name);

Return the default value listed in the data dictionary
for $field_name.
See also DBIx::IO.

=cut
sub default_value
{
    my $self = shift;
    return $self->{io}->default_value(@_);
}


=pod

=item C<required>

 $bool = $table->required($field_name);

Return true if $field_name is listed as NOT NULL in the data dictionary.
See also DBIx::IO.

=cut
sub required
{
    my $self = shift;
    return $self->{io}->required(@_);
}


=pod

=item C<field_length>

 $integer = $table->field_length($field_name);

Return the maximum length of $field_name according to the data dictionary.
Length will be compensated for numbers with decimals, and sign.
See also DBIx::IO.

=cut
sub field_length
{
    my $self = shift;
    return $self->{io}->field_length(@_);
}

=pod

=item C<add_values>

 $success = $table->add_values($add_hash);

Add a batch of COLUMN_NAME => value pairs from $add_hash.
For each value added, the corresponding <COLUMN_NAME>($val)
method will be called.

Return false if error.

=cut
sub add_values
{
    my ($self,$add) = @_;
    ref($self) || ($self->{io}->_alert("Method must be called by an object"), return undef);
    ref($add) || ($self->{io}->_alert("\$add must be a hash ref!"), return undef);
    my ($field,$val);
    while (($field,$val) = each %$add)
    {
        $field = uc($field);
        defined(eval("\$self->${field}(\$val)")) || ($self->{io}->_alert("Check routine failed for $field: $val"), return undef);
    }
    return 1;
}


=pod

=item C<existing_table_names>
 
 $sorted_arrayref = DBIx::IO::Table->existing_table_names();

Return a sorted arrayref of table names found in the
data dictionary.

Class or object method.

Return undef if db error.

=cut
sub existing_table_names
{
    my ($caller,$dbh) = @_;
    my $ioclass = $caller->_pull_driver($dbh);
    return $ioclass->existing_table_names($dbh);
}


=pod

=back

=cut


1;

__END__

=head1 BUGS

No known bugs.

=head1 SEE ALSO

L<DBIx::IO::Mask>, L<DBIx::IO::Search>, L<DBIx::IO>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

