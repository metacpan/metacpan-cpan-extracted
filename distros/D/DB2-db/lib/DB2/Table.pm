package DB2::Table;

use diagnostics;
use strict;
use warnings;
use Carp;

use DBI qw(:sql_types);

our $VERSION = '0.23';

=head1 NAME

DB2::Table - Framework wrapper around tables using DBD::DB2

=head1 SYNOPSIS

    package myTable;
    use DB2::Table;
    our @ISA = qw( DB2::Table );
    
    ...
    
    use myDB;
    use myTable;
    
    my $db = myDB->new;
    my $tbl = $db->get_table('myTable');
    my $row = $tbl->find($id);

=head1 FUNCTIONS

=over 4

=item C<new>

Do not call this - you should get your table through your database object.

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, ref $class || $class || confess("Unknown table");

    my $db = shift;
    confess("Need the db handle as parameter")
        unless $db and ref $db and $db->isa("DB2::db");
    $self->{db} = $db;

    my %tableOrder;
    my @cl = $self->column_list;
    @tableOrder{ @cl } = (0..$#cl);
    $self->{tableOrder} = \%tableOrder;

    $self;
}

=item C<data_order>

the key sub to override!  The data must be a reference to an array of hashes.  Each
element (hash) in the array must contain certain keys, others are optional.

=over 2

=item Required:

=over 2

=item C<column>

Column Name (must be upper case)

=item C<type>

SQL type or one of:

=over 4

=item C<BOOL>

This will be represented by a NOT NULL CHAR that is limited to 'Y' or 'N'.
In perl, this will be auto-converted to perlish true/false values.  An
undef will be treated as expected in perl: as false.

=item C<NULLBOOL>

As above, but NULLs will be permitted.  In this case, an 'N' in the database
will become a false, but defined, value.  Only a NULL in the database will
translate to undef in perl.

=back

=back

=item Optional:

=over 2

=item C<length>

for CHAR, VARCHAR, etc.

=item C<opts>

optional stuff - C<NOT NULL>, C<PRIMARY KEY>, etc.
(Should use C<primary> rather than C<opts =E<gt> 'PRIMARY KEY'>.)

=item C<default>

default value

=item C<primary>

true for the primary key

=item C<constraint>

stuff that is placed in the table create independantly

=item C<foreignkey>

For this column, will create a FOREIGN KEY statement.  The value here
is used during creation of the table, and should begin with the foreign
table name and include any "ON DELETE", "ON UPDATE", etc., portions. 
This may change in the future where C<foreignkey> will be itself another
hashref with all these fields.

=item C<generatedidentity>

For this column, will create as a generated identity.  If this is undef
or the word 'default', the option will be C<(START WITH 0, INCREMENT BY 1, NO CACHE)>,
otherwise it will use whatever you provide here.

=back

=back

This is somewhat based on a single column for a primary key, which is not
necessarily the "right" thing to do in relational design, but sure as heck
simplifies coding!
NOTE: Other columns may be present, but would only be used by the subclass.

=cut

sub data_order
{
    die "Gotta override data_order!";
}

sub _internal_data_order
{
    my $self = shift;
    unless ($self->{_data_order})
    {
        $self->{_data_order} = $self->data_order();
    }
    $self->{_data_order};
}

sub _internal_data_reset
{
    my $self = shift;
    delete $self->{_data_order};
    delete $self->{column_list};
    delete $self->{ALL_DATA};
    delete $self->{PRIMARY};
    delete $self->{GENERATEDIDENTITY};
}

=item C<get_base_row_type>

When allowing the framework to create your row type object because there
is no backing module, we need to know what to derive it from.  If you have
a generic row type that is derived from DB2::Row that you want all your
rows to be derived from, you can override this.

If all your empty Row types are derived from a single type that is not
DB2::Row, you should create a single Table type and have all your tables
derived from that.  That is, to create a derivation tree for your row such as:

    DB2::Row -> My::Row -> My::UserR

your derivation tree for your tables should look like:

    DB2::Table -> My::Table -> My::User

And then C<My::Table> can override C<get_base_row_type> to return
C<q(My::Row)>

=cut

sub get_base_row_type
{
    q(DB2::Row);
}


=item C<getDB>

Gets the DB2::db object that contains this table

=cut

sub getDB
{
    shift->{db};
}

=item C<schema_name>

You need to override this.  Must return the DB2 Schema to use for this
table.  Generally, you may want to derive a single "schema" class from
DB2::Table which only overrides this method, and then derive each table
in that schema from that class.

=cut

sub schema_name { confess("You must override schema_name") }

sub _connection
{
    my $self = shift;
    $self->getDB->connection;
}

sub _find_create_row
{
    my $self = shift;
    my $type = $self->{db}->get_row_type_for_table(ref $self);

    my @row = @_;

    my %params = ( _db_object => $self->getDB );
    if ($row[-1] and ref $row[-1] eq 'HASH')
    {
        %params = ( %params, %{$row[-1]} );
        pop @row;
    }

    my $data_order = $self->_internal_data_order();
    foreach my $i (0..$#$data_order)
    {
        my $column = $data_order->[$i]{column};
        if (defined $row[$i] and not exists $params{$column})
        {
            ($params{$column} = $row[$i]) =~ s/\s*$//;
        }
    }

    return $type->new(\%params);
}

=item C<create_row>

Creates a new DB2::Row object for this table.  Called instead of the
constructor for the DB2::Row object.  Sets up defaults, etc.  B<NOTE>:
this will not generate any identity column!  We leave that up to the
database, so we will retrieve that during the save before committing.

=cut

sub create_row
{
    my $self = shift;

    $self->_find_create_row( map (
                                  {
                                      $self->get_column($_, 'default');
                                  } $self->column_list
                                 ),
                                 @_ );
}

=item C<count>

Should be obvious - a full count of all the rows in this table

=cut

sub count
{
    my $self = shift;

    $self->SELECT('COUNT(*)')->[0][0];
}

=item C<count_where>

Similar to C<count>, except that the first parameter will be the SQL
WHERE condition while the rest of the parameters will be the bind
values for that WHERE condition.

=cut

sub count_where
{
    my $self = shift;

    $self->SELECT('COUNT(*)', @_)->[0][0];
}

=item C<find_id>

Finds all rows with the primary column matching any of the parameters. 
For example, $tbl->find_id(1, 2, 10) will return an array of DB2::Row
derived objects with all the data from 0-3 rows from this table, if
the primary column for that row is either 1, 2, or 10.

=cut

sub find_id
{
    my $self = shift;

    $self->find_where(
                      $self->primaryColumn . ' IN (' .
                      join (', ', map {'?'} @_) . ')',
                      @_
                     );
}

=item C<find_where>

Similar to C<find_id>, the first parameter is the SQL WHERE condition
while the rest of the parameters are the bind values for the WHERE
condition.

In array context, will return the array of DB2::Row derived objects
returned, whether empty or not.

In scalar context, will return undef if no rows are found, will return
the single Row object if only one row is found, or an array ref if more
than one row is found.

=cut

sub find_where
{
    my $self = shift;
    $self->find_join($self->full_table_name, @_);
}

=item C<find_join>

Similar to C<find_where>, the first parameter is the tables to join
and how they are joined (any '!!!' found will be replaced with the
current table's full name), the second parameter is the where condition,
if any, and the rest are bind values.

=cut

sub find_join
{
    my $self = shift;

    my @cols = $self->column_list();
    my $prefix = "";
    my $tables = shift;
    if (ref $tables and ref $tables eq 'ARRAY')
    {
        $tables = join ' ', @$tables;
    }

    if ($tables and (
                     $tables =~ /!!!\s+[Aa][Ss]\s+(\w+)/ or
                     $tables =~ /$self->full_table_name()\s+[Aa][Ss]\s+(\w+)/ or
                     $tables =~ /$self->table_name()\s+[Aa][Ss]\s+(\w+)/
                  )
        )
    {
        $prefix = "$1.";
    }

    my $ary_ref = $self->SELECT_join(
                                     {
                                         forreadonly => 1,
                                         #distinct => 1,
                                         prepare_attributes => $self->_prepare_attributes('SELECT'),
                                     },
                                     join(', ', map {$prefix . $_} $self->column_list),
                                     $tables, @_);

    my @rc;
    foreach my $row (@$ary_ref)
    {
        push @rc, $self->_find_create_row(@$row);
    }

    # array, empty or not.
    if (wantarray)
    {
        return @rc;
    }
    # if there aren't any, send back undef.
    if (scalar @rc < 1)
    {
        return undef;
    }
    # no array wanted, and only one answer, send it back.
    if (scalar @rc == 1)
    {
        return $rc[0];
    }
    # no array wanted, send back ref to array.
    return \@rc;
}

=item C<_prepare_attributes>

Internally used to set any prepare attributes.  Parameter says what
type of prepare this is, although the list is not finalised yet.

=cut

sub _prepare_attributes
{
    {}
}

=item C<_prepare>

Internally used to cache statements.  This may change to
C<prepare> if it is found to be useful.

=cut

sub _prepare
{
    my $self = shift;
    my $stmt = shift;
    my $attr = shift;

    DB2::db::_debug("$stmt\n");
    my $sth = $self->_connection->prepare_cached($stmt, $attr);

    croak "Can't prepare [$stmt]: " . $self->_connection->errstr() unless $sth;

    $sth;
}

sub _execute
{
    my $self = shift;
    my $sth  = shift;

    delete $self->{_dbi};
    unless ($sth->execute(@_))
    {
        $self->{_dbi}{err} = $sth->err;
        $self->{_dbi}{errstr} = $sth->errstr;
        $self->{_dbi}{state} = $sth->state;

        DB2::db::_debug("Failed to execute $sth->{Statement}: ", $sth->errstr());

        undef;
    }
}

=item C<dbi_err>

=item C<dbi_errstr>

=item C<dbi_state>

Shortcuts to get the DBI err, errstr, and state's, respectively.

=cut

sub dbi_err    { shift->{_dbi}{err} }
sub dbi_errstr { shift->{_dbi}{errstr} }
sub dbi_state  { shift->{_dbi}{state} }

sub _already_exists_in_db
{
    my $self = shift;
    my $obj  = shift;

    my $dbh = $self->_connection;
    my $count = 0;

    my $column = $self->primaryColumn;

    if (ref $obj)
    {
        if ($column)
        {
            $obj = $obj->column($column);
        }
    }

    if (defined $obj and not ref $obj)
    {

        #my $stmt = "SELECT COUNT(*) FROM " . $self->full_table_name .
        #    " WHERE $column IN ?";
        #$count = $dbh->selectrow_array($stmt, undef, $objval);
        $count = $self->SELECT('COUNT(*)', "$column IN ?", $obj)->[0][0];
    }

    return $count;
}

sub _update_db
{
    my $self = shift;
    my $obj  = shift;
    my $prep_attr = shift;

    # it's an update.
    my $stmt = "UPDATE " . $self->full_table_name . " SET ";
    my $prim_key = $self->primaryColumn;

    # find all modified fields.
    my @sets;
    my @newVal;
    my @bind;

    {
        for my $key (keys %{$obj->{modified}})
        {
            next if $key eq $prim_key;

            push @sets, "$key = ?";
            push @bind, [$obj->{CONFIG}{$key}];
            if ($self->get_column($key,'type') =~ /LOB$/)
            {
                push @{$bind[$#bind]}, 'SQL_BLOB';
            }
        }
    }

    if (@sets)
    {
        $stmt .= join(", ", @sets);
        $stmt .= " WHERE " . $self->primaryColumn . " IN ?";
        my $sth = $self->_prepare($stmt, $prep_attr);

        my $i = 0;
        for (; $i < @bind; ++$i)
        {
            if ($DB2::db::debug)
            {
                print "Binding ", $i + 1, " => ";
                if (scalar @{$bind[$i]} > 1 and
                    $bind[$i][1] == SQL_BLOB)
                {
                    print "[blob],", SQL_BLOB;
                }
                else
                {
                    print join(",",@{$bind[$i]});
                }
                print "\n";
            }
            $sth->bind_param($i + 1, @{$bind[$i]});
        }
        $sth->bind_param($i + 1, $obj->{CONFIG}{$prim_key});
        print "stmt = $stmt\n" if $DB2::db::debug;

        $self->_execute($sth); #, @newVal);
        $sth->finish();
        $self->commit();
    }
    else
    {
        '0E0'; # default return value.
    }
}

sub _insert_into_db
{
    my $self = shift;
    my $obj  = shift;
    my $prep_attr = shift;

    my @cols = grep {
        not $self->get_column($_, 'NOCREATE') and
            $_ ne $self->generatedIdentityColumn()
    } $self->column_list;

    my $stmt = "INSERT INTO " . $self->full_table_name . " (" .
        join(', ', @cols) .
        ") VALUES(" . join(', ', map {'?'} @cols) . ")";

    DB2::db::_debug("$stmt\n");

    my $sth = $self->_prepare($stmt, $prep_attr);

    my @bind;
    {
        my $i = 0;
        for my $key (map { uc $_ } @cols)
        {
            ++$i;

            push @bind, [$obj->{CONFIG}{$key}];
            if ($self->get_column($key,'type') =~ /LOB$/)
            {
                my $x = $obj->{CONFIG}{$key};
                #$bind[$#bind] = [\$x, {TYPE => SQL_BLOB}];
                $bind[$#bind] = [$x, {TYPE => SQL_BLOB}];
                #$bind[$#bind] = [$x,  SQL_BLOB];
            }
        }
    }
    #print STDERR "stmt = $stmt -- ", join @newVal, "\n";
    for (my $i = 0; $i < @bind; ++$i)
    {
        if ($DB2::db::debug)
        {
            print "Binding ", $i + 1, " => ";
            if (scalar @{$bind[$i]} > 1 and
                $bind[$i][1] == SQL_BLOB)
            {
                print "[blob],", SQL_BLOB;
            }
            else
            {
                print join(",", map { defined $_ ? $_ : "<NULL>" } @{$bind[$i]});
            }
            print "\n";
        }
        $sth->bind_param($i + 1, @{$bind[$i]});
    }


    my $rc = $self->_execute($sth);
    $sth->finish();
    $rc;
}

=item C<save>

The table is what saves a row.  If you've made changes to a row, this
function will save it.  Not really needed since the Row's destructor
will save, but doesn't hurt.

=cut

sub save
{
    my $self = shift;
    my $obj  = shift;
    my $prep_attr = shift;

    unless (ref $obj and $obj->isa("DB2::Row"))
    {
        croak("Got a " . ref($obj) . " which isn't a 'DB2::Row'");
    }

    if ($self->_already_exists_in_db($obj))
    {
        if ($self->primaryColumn)
        {
            $self->_update_db($obj, $prep_attr);
        }
    }
    # else it's new
    else
    {
        $self->_insert_into_db($obj, $prep_attr);
    }
}

=item C<commit>

Commits all current actions

=cut

sub commit
{
    my $self = shift;
    $self->_connection->commit;
}

=item C<delete>

Deletes the given row from the database.

=cut

sub delete
{
    my $self = shift;
    my $obj  = shift;
    my $prep_attr = shift;

    unless (ref $obj and $obj->isa("DB2::Row"))
    {
        croak("Got a " . ref($obj) . " which isn't a 'DB2::Row'");
    }

    if ($self->_already_exists_in_db($obj))
    {
        $self->_delete_db($obj, $prep_attr);
    }
}

=item delete_id

Deletes a row based on its ID.  To delete multiple IDs simultaneously,
simply pass in an array ref.

=cut

sub delete_id
{
    my $self = shift;
    my $id   = shift;
    my $prep_attr = shift;
    if (ref $id ne 'ARRAY')
    {
        $id = [ $id ];
    }

    if ($self->primaryColumn() and $self->_already_exists_in_db($id))
    {
        my $stmt = 'DELETE FROM ' . $self->full_table_name() . ' WHERE ' .
            $self->primaryColumn() . ' IN (' .
            join(',', map { '?' } @$id) . ')';
        my $sth  = $self->_prepare($stmt, $prep_attr);
        $self->_execute($sth, @$id);
        $sth->finish();
    }
}

=item delete_where

Deletes rows based on the given WHERE clause.  Further parameters are
then bound to the DELETE statement.

=cut

sub delete_where
{
    my $self = shift;
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $where = shift;

    my $stmt = 'DELETE FROM ' .
        $self->full_table_name() . ' WHERE ' . $self->_replace_bangs($where);
    my %prep_attr = exists $opts->{prepare_attributes} ? %{$opts->{prepare_attributes}} : ();
    my $sth = $self->_prepare($stmt, \%prep_attr);
    my $rc = $self->_execute($sth, @_);
    $sth->finish();
    $rc;
}

sub _delete_db
{
    my $self = shift;
    my $obj  = shift;
    my $prep_attr = shift;

    my $primcol = $self->primaryColumn;
    if ($primcol)
    {
        my $stmt = 'DELETE FROM ' . $self->full_table_name . ' WHERE ' .
            $primcol . ' IN ?';

        my $sth = $self->_prepare($stmt, $prep_attr);
        $self->_execute($sth, $obj->column($primcol));
        $sth->finish();
        $self->commit();
    }
    else
    {
        my $stmt = 'DELETE FROM ' . $self->full_table_name . ' WHERE ' .
            join (' AND ', map { "$_ IN ?" } $self->column_list());
        my $sth = $self->_prepare($stmt, $prep_attr);
        $self->_execute($sth, map { $obj->column($_) } $self->column_list());
        $sth->finish();
        $self->commit();
    }
}

=item C<SELECT>

Wrapper around performing an SQL SELECT statement.

Parameters:

=over 4

=item *

B<Optional>: Hashref of options.  Options may include:

=over 4

=item with

This is the WITH clause tacked on to the front of the SELECT statement,
if any.  (!!! replacement as per SELECT_join is done on this.)

Or, this can be a hashref:

    with => {
        temp2 => {
            fields => [ qw/empno firstnme/ ],
            as => q[SELECT EMPNO, FIRSTNAME FROM !!!,!XYZ! WHERE ...],
        },
        temp1 => {
            as => q[...],
        },
    },

This will create a WITH clause like this:

    WITH temp1 AS (...), temp2 (empno,firstname) AS (SELECT EMPNO, FIRSTNAME
    FROM !!!,!XYZ! WHERE ...

(except that !!! and !XYZ! will be expanded in the context of the current
table) which will then go in the front of the rest of the SELECT statement.

=item distinct

If true, the DISTINCT keyword will be added prior to the column names
resulting in a return set where each row is unique.  Somewhat useless if
the columns are all columns or include UNIQUE columns.

=item forreadonly

Set the query up as a "FOR READ ONLY" statement (potential performance
enhancement).

=item tables

This is either a string with the table names, or an array ref of table names.
Used in joins.

=item prepare_attributes

This is used in the prepare statement as extra options - see DBD::DB2
under the heading C<Statement Attributes>.  The value here must be a
hashref ready to be passed in to the prepare function.

=back

=item *

Arrayref of columns I<or> string of columns, seperated
by commas.  For example:

    [ qw(col1 col2 col3) ]

or
    'col1,col2,col3'

=item *

B<Optional>: Where-clause for SQL query.

=item *

B<Optional>: Bind values for the where-clause - this is not an arrayref
but the actual elements.

=back

For example:

    $table-E<gt>SELECT({distinct=>1},[qw(col1 col2)],
                       'col3 in (?,?,?)', 'blah', 'burg', 'frob');

This will result in an SQL statement of:

    SELECT DISTINCT col1, col2 FROM myschema.mytable WHERE col3 in (?,?,?)

And ('blah', 'burg', 'frob') will be bound to the ?'s.

=cut

sub SELECT
{
    my $self = shift;
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $cols = shift;
    my $where = shift;
    my @params = @_;

    if (ref $cols and ref $cols eq 'ARRAY')
    {
        $cols = join ', ', @$cols;
    }

    my $select_modifier = '';
    my $table = $self->full_table_name();

    # is this a join?
    if (exists $opts->{tables})
    {
        $table = $opts->{tables};
        if (ref $table and ref $table eq 'ARRAY')
        {
            $table = join ', ', @$table;
        }
        $self->_replace_bangs($table);
    }

    # distinct?
    $select_modifier .= 'DISTINCT ' if $opts->{distinct};

    my $stmt = '';
    $stmt .= 'WITH ' . $self->_with($opts->{with}). ' ' if $opts->{with};
    $stmt .= 'SELECT ' . $select_modifier . $cols . ' FROM ' . $table;
    $stmt .= ' WHERE ' . $self->_replace_bangs($where) if $where;
    $stmt .= ' FOR READ ONLY' if $opts->{forreadonly};

    my %prep_attr = exists $opts->{prepare_attributes} ? %{$opts->{prepare_attributes}} : ();



    my $sth = $self->_prepare($stmt, \%prep_attr);
    $self->_execute($sth, @params) or die "Failed to execute $stmt: " . $self->dbi_errstr();

    if ($opts->{as_hashes})
    {
        my @r;
        while (my $h = $sth->fetchrow_hashref())
        {
            push @r, $h;
        }
        $sth->finish();
        return wantarray ? @r : \@r;
    }

    if ($opts->{as_hash})
    {
        return $sth->fetchall_hashref($opts->{as_hash});
    }

    return $sth->fetchall_arrayref();
}

sub _with
{
    my $self = shift;
    my $with = shift;

    if (ref $with)
    {
        my $substmt = join ', ', map {
            my $fields = '';
            if ($with->{$_}{fields})
            {
                $fields = $with->{$_}{fields};
                if (ref $fields)
                {
                    $fields = join ',', @$fields;
                }
                $fields = " ($fields)"
            }
            my $as = $self->_replace_bangs($with->{$_}{as});
            $as = " AS ($as)";

            "$_$fields$as";
        } sort keys %$with;
    }
    else
    {
        $with;
    }
}

=item C<SELECT_distinct>

Wrapper around performing an SQL SELECT statement with distinct rows only
returned.  Otherwise, it's exactly the same as C<SELECT> above

=cut

sub SELECT_distinct
{
    my $self = shift;
    my $opts = {};
    my $cols = shift;

    if (ref $cols and ref $cols eq 'HASH')
    {
        $opts = $cols;
        $cols = shift;
    }

    $opts->{distinct}++;

    return $self->SELECT($opts, $cols, @_);
}

=item C<SELECT_join>

Wrapper around performing an SQL SELECT statement where you may be joining
with other tables.  The first argument is the columns you want, the second
is the tables, and how they are to be joined, while the third is the WHERE
condition.  Further parameters are bind values.  Any text matching '!!!' in
the columns text will be replaced with this table's full table name.  Any
text matching '!(\S+?)!' will be replaced with $1's full table name.

=cut

sub _replace_bangs
{
    my $self = shift;

    $_[0] =~ s/!!!/$self->full_table_name()/ge;
    $_[0] =~ s/!(\S+?)!/$self->getDB()->get_table("$1")->full_table_name()/ge;
    $_[0];
}

sub SELECT_join
{
    my $self   = shift;
    my $opts = {};
    my $cols = shift;

    if (ref $cols and ref $cols eq 'HASH')
    {
        $opts = $cols;
        $cols = shift;
    }

    $opts->{tables} = shift;
    return $self->SELECT($opts, $cols, @_);
}

=item C<table_name>

The name of this table, excluding schema.  This will default to the
part of the current package after the last double-colon.  For example,
if your table is in package "myDB2::foo", then the table name will be
"foo".

=cut

sub table_name
{
    my $self = shift;
    unless (exists $self->{table_name})
    {
        my $type = ref $self;
        ( my $tbl = $type ) =~ s/.*::(\w+)/$1/;
        $self->{table_name} = uc $tbl;
    }
    $self->{table_name};
}

=item C<full_table_name>

Shortcut to schema.table_name

=cut

sub full_table_name
{
    my $self = shift; 
    unless (exists $self->{full_table_name})
    {
        $self->{full_table_name} = uc $self->schema_name . '.' . $self->table_name;
    }
    $self->{full_table_name};
}

=item C<column_list>

Returns an array of all the column names, in order

=cut

sub column_list
{
    my $self = shift;
    if (not exists $self->{column_list})
    {
        $self->{column_list} = [map { $_->{column} } @{$self->_internal_data_order}];
    }
    @{$self->{column_list}}
}

=item C<all_data>

Returns a hash ref which is all the data from C<data_order>, but in no
particular order (it's a hash, right?).

=cut

sub all_data
{
    my $self = shift;
    unless ($self->{ALL_DATA})
    {
        foreach my $h (@{$self->_internal_data_order()})
        {
            $self->{ALL_DATA}{uc $h->{column}} = $h;
        }
    }
    $self->{ALL_DATA}
}

=item C<get_column>

Gets information about a column or its data.  First parameter is the
column.  Second parameter is the key (NAME, type, etc.).  If
the key is not given, a hash ref is returned with all the data for
this column.  If the key is given, only that scalar is returned.

=cut

sub get_column
{
    my $self = shift;
    my $column = uc shift;
    my $data = @_ ? lc shift : undef;
    my $all_data = $self->all_data;

    return undef unless exists $all_data->{$column};

    if ($data)
    {
        exists $all_data->{$column}{$data} ? $all_data->{$column}{$data} : undef;
    }
    else
    {
        $all_data->{$column};
    }
}

=item C<primaryColumn>

Find the primary column.  First time it is called, it will determine
the primary column, and then it will cache this for later calls.  If
you want a table with no primary column, you must override this method
to return undef.

If no column has the primary attribute, then the last column is
defaulted to be the primary column.

=cut

# Find the primary column (and cache it)
sub primaryColumn
{
    my $self = shift;
    # Check cache.
    if (not exists $self->{PRIMARY})
    {
        # default to last one.
        $self->{PRIMARY} = $self->_internal_data_order()->[$#{$self->_internal_data_order()}]{column};

        my $data_order = $self->_internal_data_order();
        for (my $i = 0; $i < scalar @$data_order; ++$i)
        {
            if (exists $data_order->[$i]{primary} and $data_order->[$i]{primary})
            {
                $self->{PRIMARY} = $data_order->[$i]{column};
                last;
            }
        }
    }
    $self->{PRIMARY};
}

=item C<generatedIdentityColumn>

Determine the generated identity column, if any.  This is determined by
looking for the string 'GENERATED ALWAYS AS IDENTITY' in the opts of
the column.  Again, this is cached on first use.

=cut

sub generatedIdentityColumn
{
    my $self = shift;
    if (not exists $self->{GENERATEDIDENTITY})
    {
        $self->{GENERATEDIDENTITY} = '';
        foreach my $col (@{$self->_internal_data_order()})
        {
            if (exists $col->{generatedidentity} or
                (
                 exists $col->{opts} and
                 $col->{opts} =~ /GENERATED ALWAYS AS IDENTITY/i)
               )
            {
                $self->{GENERATEDIDENTITY} = $col->{column};
                last;
            }
        }
    }
    $self->{GENERATEDIDENTITY};
}

=item C<table_exists>

Check if the table already exists.  Normally only called by create_table.

=cut

sub table_exists
{
    my $self = shift;
    my $dbh = $self->_connection;
    my @tables = $dbh->tables(
                              {
                                  TABLE_SCHEM => uc $self->schema_name,
                                  TABLE_NAME  => uc $self->table_name,
                              }
                             );
    die "Unexpected - more than one table with same schema/name!" if scalar @tables > 1;
    scalar @tables;
}

# INTERNAL - get current table structure (column names)
sub create_table_get_current
{
    my $self = shift;
    my $dbh = $self->_connection;

    my @row;
    if ($self->table_exists())
    {
        my $query = 'SELECT * FROM ' . $self->full_table_name . ' WHERE 1 = 0';
        my $sth  = $dbh->prepare($query);

        $self->_execute($sth);
        @row = @{$sth->{NAME}};
        $sth->finish;
    }
    @row;
}
# INTERNAL - common code between CREATE and ALTER - column definitions
sub _create_table_column_definition
{
    my $self = shift;
    my $column = shift;
    my $tbl = $column->{column} . ' ';
    $tbl   .= uc $column->{type} =~ /(?:NULL)?BOOL/ ? 'CHAR' : $column->{type};
    $tbl   .= ' (' . $column->{length} . ')' if exists $column->{length};
    $tbl   .= ' ' . $column->{opts} if $column->{opts};
    $tbl   .= ' NOT NULL' if 
        (
         $column->{primary} or
         uc $column->{type} ne 'NULLBOOL' and (not $column->{opts} or $column->{opts} !~ /NOT NULL/)) or
            ($column->{type} eq 'BOOL' and $column->{opts} !~ /NOT NULL/);
    if (exists $column->{sqldefault})
    {
        $tbl .= ' WITH DEFAULT ' . $column->{sqldefault};
    }

    $tbl   .= ' CHECK (' . $column->{column} . q[ in ('Y','N'))] if uc $column->{type} eq 'BOOL';
    $tbl   .= ' CHECK (' . $column->{column} . q[ in ('Y','N') OR ] . $column->{column} . q[ IS NULL)] if uc $column->{type} eq 'NULLBOOL';
    if (exists $column->{generatedidentity})
    {
        $tbl .= ' GENERATED ALWAYS AS IDENTITY ';
        if (not defined $column->{generatedidentity} or 
            $column->{generatedidentity} eq 'default')
        {
            $tbl .= '(START WITH 0, INCREMENT BY 1, NO CACHE)';
        }
        else
        {
            $tbl .= $column->{generatedidentity};
        }
    }

    $self->_replace_bangs($tbl);
}
# Create the table as given by data_order.

=item C<create_table>

Creates the current table.  Normally only called by L<DB2::db::create_table>.

=cut

sub create_table
{
    my $self = shift;
    my $dbh = $self->_connection;
    my %current_col_names = map { $_ => 1 } $self->create_table_get_current();

    if (scalar keys %current_col_names == 0)
    { # new table
        my $tbl = 'CREATE TABLE ' . $self->full_table_name . ' (';
        my @columns;
        my @constraints;
        my @foreign_keys;
        foreach my $f ( $self->column_list )
        {
            my $column = $self->get_column($f);
            push @columns, $self->_create_table_column_definition($column);
            if (exists $column->{constraint})
            {
                push @constraints, map { 
                    my $x = 'CONSTRAINT ' . $_;
                    $self->_replace_bangs($x);
                } ref($column->{constraint}) eq 'ARRAY' ? @{$column->{constraint}} : $column->{constraint};
            }
            if (exists $column->{foreignkey})
            {
                push @foreign_keys, map {
                    my $x = 'FOREIGN KEY (' . $column->{column} . ') REFERENCES ' . $_;
                    $self->_replace_bangs($x);
                } ref($column->{foreignkey}) eq 'ARRAY' ? @{$column->{foreignkey}} : $column->{foreignkey};
            }
        }
        if ($self->primaryColumn)
        {
            push @constraints, 'PRIMARY KEY (' . $self->primaryColumn . ')';
        }
        $tbl .= join(', ', @columns, @constraints, @foreign_keys);
        $tbl .= ') DATA CAPTURE NONE';

        print "$tbl\n";
        unless ($dbh->do($tbl))
        {
            print $DBI::err, '[', $DBI::state, '] : ', $DBI::errstr, "\n";
        }

        $self->create_table_initialise('CREATE', $self->column_list());
    }
    else
    { # existing table - anything need to be updated?
        my $alter = 'ALTER TABLE ' . $self->full_table_name;
        my @add = grep { not exists $current_col_names{uc $_} } ($self->column_list);

        if (scalar @add)
        {
            foreach my $add (@add)
            {
                my $column = $self->get_column($add);
                $alter .= ' ADD ' . $self->_create_table_column_definition($column);
            }
            print $alter, "\n";
            $dbh->do($alter);

            $self->create_table_initialise('ALTER', @add);
        }
    }

}

=item C<create_table_initialise>

A hook that will allow you to initialise the table immediately after
its creation.  If the table is newly created, the only parameter will
be 'CREATE'.  If the table is being altered, the first parameter will
be 'ALTER' while the rest of the parameters will be the list of columns
added.

The default action is mildly dangerous.  It grants full select, insert,
update, and delete authority to the user 'nobody'.  This is the user
that many daemons, including the default Apache http daemon, run under.
 If you override this, you can do whatever you want, including nothing.
 This default was put in primarily because many perl DBI scripts are
expected to also be CGI scripts, so this may make certain things
easier.  This does not change the fact that when this grant is executed
you will need some admin authority on the database.

=cut

sub create_table_initialise
{
    my $self = shift;
    my $action = shift;
    if ($action eq 'CREATE')
    {
        # default: grant authority to nobody (useful for web apps)
        my $grant =
            'GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE ' .
            $self->full_table_name .
            ' TO USER NOBODY';
        $self->_connection->do($grant);
    }

}

=back

=cut

1;
