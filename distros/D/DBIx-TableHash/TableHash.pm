#!/usr/bin/perl
## Emacs: -*- tab-width: 4; -*-

use strict;

package DBIx::TableHash;

use vars qw($VERSION);              $VERSION = '1.04';

=pod

=head1 NAME

DBIx::TableHash - Tie a hash to a mysql table + SQL utils

=head1 SYNOPSIS

    use DBIx::TableHash;
    my $DBHash = DBIx::TableHash->create_or_die
    (my $Params =
     {
         DBIDriver      => 'mysql', 
         Database       => 'mydatabase',
         HostName       => 'localhost', 
         Port           => undef,
         Login          => '',
         Password       => '',

         TableName      => 'SalesPeople',
         KeyField       => 'FullName',  

         ## For multi-key lookup:
         FixedKeys      => {AreaCode   => 415,
                            StatusCode => 'Active',
                            RecordType => 'Primary'},
         
         ## To retrieve a single value:
         ValueField     => 'PhoneNumber',

         ## ... or for "multi-value" retrieval...
         ValueField     => undef,

         ## ... optionally specifying...
         RetrieveFields => [qw(Title Territory Quota)],
        
         ## For caching:
         CacheMode => 'CacheBeforeIterate'
         ## or...
         CacheMode => 'CacheOneTime'
         ## or...
         CacheMode => 'CacheNone'
        }
     );

    my %DBHash; tie(%DBHash, 'DBIx::TableHash', $Params);

    my $DBHash = DBIx::TableHash->create($Params) or die "Help!";
    my $DBHash = DBIx::TableHash->create_or_die($Params);

    my $DBHash = DBIx::TableHash->create_copy($Params) or die "Help!";
    my $DBHash = DBIx::TableHash->create_copy_or_die($Params);

=head1 OVERVIEW

All parameters are passed via a single anonymous hash.

All parameters are optional, but you'll almost always need to specify
Database, TableName, and KeyField.

Omitting ValueField puts the hash in "multi-value" mode, where you
store/retrieve a hash of fields/values instead of a single value.  In
"multi-value" mode all fields in each record are retrieved on every
fetch; RetrieveFields limits fields retrieved to a specified list.

Specifying FixedKeys puts the hash in "multi-key" mode, in which only
a subset of the database table, corresopnding to records that match
the spec in FixedKeys, is operated on.

Cache modes reduce querying, but lose synchronization and hog memory.

The object is designed to be easy subclass.  Try making a subclass
that sets defaults for all or most of the parameters, so the caller
doesn't have to supply any at instantiation time.

"create_copy" methods efficiently create and return potentially huge
untied hash "snapshot" of the same data that would have been retrieved
by the corresponding tied hash.


=head1 DETAILS

The DBHash object is designed to tie a hash to a table or a subset of
records in a table in a DBI database (only tested with mysql in the
current version, but expected to work with any vendor).

If the table only has a single KeyField, which this modules assumes to
be a unique key field in the table, then the hash keys are stored and
retrieved in that field, and the values are saved in and returned from
the ValueField.  Records are automatically created and deleted as the
hash is used like any other hash.  (If the table is read-only, be sure
not to try to store into the tied hash!)

To access only a subset of the records in a table, you may specify
hash of "FixedKeys", which is a hash mapping OTHER field names to
fixed values that those fields must have for all lookups, updates, and
inserts done via the hash interface.  This sets up a virtual hash
corresponding to a subset of the table where N key fields are fixed at
given values and a different key field may vary.

There are several ways to use this module.

Quick and dirty mode (single-key, single-value) using tie:

    use DBIx::TableHash;
    my %PhoneNumbers;
    tie (%PhoneNumbers, 'DBIx::TableHash', 
         {Database      => 'mydatabase', 
          TableName     => 'SalesPeople',
          KeyField      => 'FullName',
          ValueField    => 'PhoneNumber'})
        or die "Failed to connect to database";

Then you can use %PhoneNumbers like any hash mapping FullName to
PhoneNumber.  Any retrieval of data results in corresponding SQL
queries being made to the database.  Modifying the hash modifies the
database.


Even quicker mode using create():

For convenience, you can use the create() class method to do the tying
for you.  It creates an anonymous hash, ties it and, returns it.  It
takes the same parameters as new() and tie().

    use DBIx::TableHash;
    my $PhoneNumbers = DBIx::TableHash->create(......)
        or die "Failed to connect to database";

Quicker still using create_or_die():

    use DBIx::TableHash;
    my $PhoneNumbers = DBIx::TableHash->create_or_die(......);

create() carps and returns undef if it can't connect to the database.

create_or_die() croaks (dies) your program, with the same error
message as create() would have given.

Normally, create() will carp() (warn) you with an error message upon
failure, and return undef.

If you would have handled your error by saying "or die", and ar
comfortable with create's error message rather than your own, then
create_or_die() is for you.

Using one of the create() methods instead of new() and tie() works
with all of the different modes discussed below, and all parameters
are the same either way.


Cooler subclassing mode:

You can create a simple subclass that provides default parmas in an
initialize method so they don't have to be provided by the caller ...

    ### MyCompany/SalesPhoneHash.pm:

    #!/usr/bin/perl

    use strict;

    package   MyCompany::SalesPhoneHash;
    use       vars qw(@ISA);
    use       DBIx::TableHash;
    @ISA = qw(DBIx::TableHash);

    sub initialize
    {
        my $this = shift;

        $this->{Database}   ||= 'mydatabase';   ## Name of database to connect to.
        $this->{TableName}  ||= 'SalesPeople';  ## Table in which to store the data
        $this->{KeyField}   ||= 'FullName';     ## Name of the key field
        $this->{ValueField} ||= 'PhoneNumber';  ## Name of the value field.

      done:
        return($this->SUPER::initialize());
    }
    1;

Then to use the object, your script merely does:

    use MyCompany::SalesPhoneHash;
    my %PhoneNumbers = MyCompany::SalesPhoneHash->create_or_die();

Of course, when instantiating a subclass, if you wish you can still
override any parameters you wish, as long as the initialize() method
in the subclass uses ||= rather than = to set defaults for any
unspecified parameters.


Multi-key mode: 

You may also use the "FixedKeys" parameter to specify a hash of some
additional key fields and their fixed values that must match exactly
for any records that are retrieved, deleted, or created by the tied
object, effectively allowing the hash to operate on only a subset of
the data in the database.  This is typically helpful in a multi-keyed
table where, for the purposes of your script, all key values should be
fixed except one (and that one is the hash key).

    use DBIx::TableHash;
    my $PhoneNumbers = 
        DBIx::TableHash->
            create_or_die(
                          {Database     => 'mydatabase', 
                           TableName    => 'SalesPeople',
                           KeyField     => 'FullName',
                           ValueField   => 'PhoneNumbers',
                           FixedKeys        =>
                           {AreaCode        => 415,
                            StatusCode      => 'Active',
                            RecordType      => 'Primary'}});


Multi-value mode:

If instead of getting and setting a single value, you'd like to get or
set a hash of all fields in the record, simply don't specify
ValueField, and the object will use "multi-value" mode, where an
entire record, as a hash, is gotten or set on each fetch or store.
Feel free to combine this mode with multi-key mode.

When storing a record in multi-value mode, if the record already
exists, only the specified fields are overwritten.  If it did not
already exist, then only the specified fields will be written and the
others will be NULL or defaulted according to the table schema.

When storing a record in multi-value mode, you can't change the values
of the primary key field or any other key field specified in FixedKeys
(if any), since that would mess up the whole point of this module
which is to leave the main key and fixed keys fixed while mucking with
the other values in the record.  Any changed values in key fields are
simply ignored.

    use DBIx::TableHash;
    my $SalesPeopleTable = 
        DBIx::TableHash->
            create_or_die(
                          {Database     => 'mydatabase', 
                           TableName    => 'SalesPeople',
                           KeyField     => 'FullName'});

    my $SalesPersonFullName = "Joe Jones";
    my $EntireRecord = $SalesPeopleTable->{$SalesPersonFullName};

When fetching records in multi-value mode, you can limit the list of
returned fields to a subset of all available fields in case there
might be some very big ones that you don't want to waste bandwidth
getting.  Just set the RetrieveFields parameter to an anonymous list
of the fields you care to retrieve.  (This setting does not limit
the fields you can SET, just the ones that get retrieved.)

    use DBIx::TableHash;
    my $SalesPeopleTable = 
        DBIx::TableHash->
            create_or_die(
                          {Database     => 'mydatabase', 
                           TableName    => 'SalesPeople',
                           KeyField     => 'FullName',
                           RetrieveFields=> [qw(Territory Quota)]});

Warning: 

In multi-value mode, you might expect that this:

    $Hash->{$MyKey}->{FieldX} = 'foo';

would set the value of the FieldX field in the appropriate record in
the database.  IT DOES NOT.

This is because the anonymous hash returned by $Hash->{$MyKey} is not
in any way tied back to the database.  You'd have to retrieve the
record hash, change any value in it, and then set $Hash->{$MyKey} back
to it.  

Making the above syntax work with a multi-valued tied hash to set a
value in the database is a possible future enhancement under
consideration by the author.  Let me know if you would like to have
that work.  

In the meanwhile, here's how you do could do it:


    (my $Record = $Hash->{$MyKey})->{FieldX} = 'foo';
    $Hash->{$MyKey}->{FieldX} = $Record;

WARNING: If you use the above approach to update a record in
multi-value mode, beware that there's potentially a race condition in
the above code if someone else updates the same record after you've
copied it but before you've modified and set it.  So use this
technique with caution and understanding.  If in doubt, don't use this
module and instead use an SQL query to update the record in a single
transaction.  Only you know the usage patterns of your database, the
concurrency issues, and the criticality of errors.


Caching modes:

The object has several ways it can cache data to help minimize the
number of SQL queries to the database, at the expense of potentially
dramatically increased memory usage.  The following cache parameters
can be specified to enable caching:

    CacheMode => 'CacheBeforeIterate'

    CacheMode => 'CacheOneTime'

To disable caching, specify:

    CacheMode => 'CacheNone'

(You can also assign undef to CacheMode, but you'll get warnings.)

Normally, every time you fetch a value from the hash, it makes an SQL
query to the database.  This, of course, is the intended and normal
mode of operation.  

Unfortunately, in Perl, just calling values(%Hash) or each(%Hash) or
even copying the hash with {%Hash} results in a separate FETCH, and
consequently, a separate SQL query made by this module, for each item.
This could result in thousands of queries just to fetch all the values
from a thousand-item table in the database.

However, often you want to iterate over all the elements of a hash
without it having to go back to the database and issue another query
for each item that you retrieve.

Using the 'CacheBeforeIterate' mode, all keys and values are cached
upon each call to FIRSTKEYS (i.e. at the start of any iteration or
enumeration).  Then, any subsequent calls to FETCH data from the hash
retrieve it from the cache instead of doing an SQL query.  STORING or
DELETING any items from the hash results in them being stored and
deleted from both the database and the cache.

Using the CacheOneTime mode, the full cache is built at object
instantiation and time never fully rebuilt.  In fact, its contents
never change unless you make alterations by using it to store into
and/or delete from the database.

CACHE WARNING: With both caching modes, of course, you must be
comfortable with the fact that the data being retrieved is a
"snapshot" of the database and consequently will not reflect updates
done by other parties during the lifetime of the object; it will only
reflect updates that you make by storing or deleting values from it.
If other people are using the database simultaneously, your cache and
the actual data could "drift" out of agreement.  This is mainly
dangerous to you, not others, unless you then go make updates to the
data based on potentially outdated values.


All modes may be combined...

All modes and parameters are orthogonal, so any combination of
parameters may be specified, with the exception that the
RetrieveFields parameter is only meaningful when ValueField is not
unspecified.

With subclassing, you may create objects that pre-specify any
parameters, even those that affect the major modes of operation.  For
example, you may combine the subclassing technique and the multi-key
mode to make an object that accesses only the appropriate subset of a
multi-keyed table without requiring any parameters to be supplied by
the caller.


Getting a COPY of the data instead of a tied hash:

What if you just want a big copy -- a snapshot -- of the data in the
table, in a regular old hash that's no longer tied to the database at
all?  (Memory constraints be damned!)

Just use the create_copy() or create_copy_or_die() methods.  They work
just like create() and create_or_die(), but instead of returning a
tied object, they just return a potentially huge hash containing a
copy of all the data.

In other words:

   create_copy()        is equivalent to: {%{create() || {} }}
   create_copy_or_die() is equivalent to: {%{create_or_die()}}

... but the _copy methods are more efficient because internally, a
caching mode is used to minimize the queries to the database and
generate the hash as efficiently as possible.

In all other respects, create_copy() and create_copy_or_die() perform
exactly like their non-copying namesakes, taking all the same
parameters, except CacheMode which is not relevant when making a
static copy.

Please remember that the object returned by the _copy methods is no
longer tied to the database. 


=head1 PARAMETER SUMMARY

The full list of recognized parameters is:

DBI Parameters

    Param       Default         Description
    ------------------------------------------------------------------------
    DBIDriver   'mysql'         Name of DBI driver to try to use (only
                                    mysql has currently been tested by the
                                    author).

    HostName    'localhost'     Host name containing the database and table;

    Port        undef           Port number if different from the standard.
    
    Login       ''              Login to use when connecting, if any.

    Password       ''               Password to use when connecting, if any.

SQL Parameters

    Param       Default         Description
    ------------------------------------------------------------------------
    Database    ''              Name of database to connect to.

    TableName   ''              Table to connect to.

    KeyField    ''              Name of field in which lookup key is found.

    ValueField  ''              Name of field to pull value from.
                                If empty or undef, then a
                                multi-value hash is used both for
                                saving and retrieving.  This is
                                called "multi-value mode".

Module Parameters

    Param       Default         Description
    ------------------------------------------------------------------------
    FixedKeys   {}              If supplied, gives names and
                                fixed, hardcoded values that other
                                keys in the table must have; this
                                effectively limits the scope of
                                the tied hash from operating over
                                the entire table to operating over
                                just the subset of records that
                                match the values in FixedKeys.
                                This is called "multi-key mode".

    RetrieveFields  []          In multi-value mode, limits the
                                fields that are retrieved; default
                                is all fields in the record.

=head1 SUPPORT

I am unable to provide any technical support for this module.  The
whole reason I had to make it was that I was way too busy (lazy?) to
write all that SQL code...

But you are encouraged to send patches, bug warnings, updates, thanks,
or suggestions for improvements to the author as listed below.

Just be aware that I may not have time to respond.  Please be sure to
put the name of this module somewhere in the Subject line.

The code is a pretty simple tied hash implementation, so you're on
your own to debug it.  If you're having trouble debugging via the
"tie" interface, try instantiating an object directly (or retrieving
it when you tie (see perltie)) and calling its methods individually.
Use the debugger or Data::Dumper to dump intermediate values at key
points, or whatever it takes.  Use your database server logs if you
want to see what SQL code is getting generated.  Or contribute a
debugging mode to this module which prints out or logs the SQL
statements before executing them.

=head1 BUGS/GOTCHAS

Problem: If you iterate or enumerate the hash, all keys get pulled in
from the database and stay stored in memory for the lifetime of the
object.  FIRSTKEY, which is called every time you do a keys(), each()
or any full iteration or enumeration over the tied hash (such as
copying it) retrieves and hangs on to a full list of all keys in
KeyField.  If the keys are long or there are lots of them, this could
be a memory problem.  (Don't confuse this with CacheMode in which BOTH
keys AND values are stored in memory.)

Solutions:  

    1) Don't iterate or enumerate.  Just fetch and store.
    2) Only iterate or enumerate on short tables. 
    3) LValue or RValue hash slices should be safe to do.


=head1 INSTALLATION

Using CPAN module:

    perl -MCPAN -e 'install DBIx::TableHash'

Or manually:

    tar xzvf DBIx-TableHash*gz
    cd DBIx-TableHash-?.??
    perl Makefile.PL
    make
    make test
    make install

=head1 SEE ALSO

The DBIx::TableHash home page:

    http://christhorman.com/projects/perl/DBIx-TableHash/

The implementation in TableHash.pm.

The perlref and perltie manual pages.

The mysql home page:

    http://mysql.com/

=head1 THANKS

Thanks to Mark Leighton Fisher <fisherm@tce.com> for providing a patch
to fix -w support (change in standard "none" setting of CacheMode from
undef to CacheNone).

=head1 AUTHOR

Chris Thorman <chthorman@cpan.org>

Copyright (c) 1995-2002 Chris Thorman.  All rights reserved.  

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


use DBI;
use Carp;

## We require Data::Dumper not only because it's my favorite debugging
## tool and nobody should be without it, but also because it's helpful
## in generating error messages when lots of complex data structures
## are being slung around.

use Data::Dumper; local $Data::Dumper::Deepcopy = 1;


############ CLASS HELPER METHODS

### create
### create_or_die

### These are class methods, provided for convenience, that take the
### same parameters as new/tie, do does the tying for you and return
### an anonymous hash.  Why make the end-user do the messy tying?

### create carps on failure.
### create_or_die croaks on failure.

sub create
{
	my $Class = shift;
	my ($Params, $OrDie) = @_;
	
	my $ThisHash = {};
	
	&{$OrDie?\&confess:\&carp}("Failed to create a new $Class with params " . &Dumper($Params) ), goto done 
		unless 
			my $ThisObject = tie (%$ThisHash, $Class, $Params);	## Calls new()
	
	## Return undef if failure or the tied anonymous hash if success.
	return($ThisObject && $ThisHash);
}

sub create_or_die
{
	my $Class = shift;
	my ($Params) = @_;

	return($Class->create($Params, 'OrDie'));
}

sub create_copy
{
	my $Class = shift;
	my ($Params, $OrDie) = @_;

	## Force the new object into "CacheOneTime" mode, which caches all
	## data immediately.

	my $TiedHash = $Class->create({%{$Params || {}}, CacheMode => 'CacheOneTime'}, $OrDie);

	## Then return the cached hash and abandon the original object.
	return($TiedHash && (tied(%$TiedHash))->{_CacheHash});
}

sub create_copy_or_die
{
	my $Class = shift;
	my ($Params) = @_;

	return($Class->create_copy($Params, 'OrDie'));
}


############### CONSTRUCTOR

### new

### Probably you won't need to override this when subclassing.
### Instead, override the initialize() method.

sub new 
{
	## First arg to new is always either class name or a template
	## object.  This allows $obj->new() or CLASS->new().

	## Single additional argument to new is an optional anonymous hash
	## of parameters.  See the initialize method, below, for a list of
	## parameters that can be passed (and will be defaulted for you if
	## not passed).

	my $ClassOrObj = shift;	
	my ($Params) = @_;

	my $class = ref($ClassOrObj) || $ClassOrObj;

	## Shallow-copy all params from template object and/or optional
	## $Params hash into new hash.

	my $this = {%{(ref($ClassOrObj)           ? $ClassOrObj : {})},
				%{(ref($Params    ) eq 'HASH' ? $Params     : {})}};

	bless $this, $class;
	return ($this->initialize() ? $this : undef);
}

### initialize

### This method defaults any public and/or internal parameters, does
### some precalculations, and otherwise initializes the object.  If
### you override this method, please remember to call
### $this->SUPER::initialize() when you're finished with your own
### initializations.

sub initialize
{
	my $this = shift;
	my $Class = ref($this);

	my $Success;

	## These parameters are used by various routines; the defaults
	## here are frequently overridden by instantiation or by
	## subclasses (either by passing a hash of params in the new()
	## method, or by overriding this initialize method in a subclass
	## and setting or defaulting some or all of them before running
	## the code below by calling SUPER::initialize().

	## Make the most reasonable defaults for all parameters.

	$this->{DBIDriver}	||= 'mysql';		## Name of DBI driver to try to use 
											## (only mysql is currently tested or supported).

	$this->{HostName}   ||= 'localhost';	## Host name containing the database and table;
	$this->{Port}	    ||= undef;			## Port number if different from the standard.

	$this->{Database}	||= '';				## Name of database to connect to.
	$this->{Login}		||= '';				## Login    to use when connecting, if any.
	$this->{Password}	||= '';				## Password to use when connecting, if any.

	$this->{TableName}	||= '';				## Table to connect to.

	$this->{KeyField}	||= '';				## Name of field in which lookup keys are found.
	$this->{ValueField}	||= '';				## Name of field in which value keys are found.

	$this->{CacheMode}	||= "CacheNone";	## Cache mode; none by default.

	$this->{FixedKeys}		= {} unless ref($this->{FixedKeys}     ) eq 'HASH';  ## Ensure a hash ref
	$this->{RetrieveFields} = [] unless ref($this->{RetrieveFields}) eq 'ARRAY'; ## Ensure an array ref

	## This module can't do anything unless at least these three
	## fields have been specified by this point:

	carp("Must specify Database to connect to for $Class"), goto done unless $this->{Database};
	carp("Must specify TableName for $Class, database: $this->{Database}"), goto done unless $this->{TableName};
	carp("Must specify KeyField for $Class / table: $this->{TableName}"), goto done unless $this->{KeyField};


	## Make sure that all table names and field names seem to be valid
	## and not attempts to screw with our SQL statements.  (I.e. they
	## must consist only of word characters.)

	foreach (
			 $this->{TableName}, 
			 $this->{KeyField}, 
			 ($this->{ValueField} ? $this->{ValueField} : ()),
			 keys %{$this->{FixedKeys}},
			 @{$this->{RetrieveFields}},
			 )
	{
		carp("Invalid table or field name: $_"), goto done unless /^\w+$/;
	}
	
	## Connect to the database or fail trying; initializes $this->{_dbh};
	goto done unless $this->Connect();

	my $dbh = $this->{_dbh};

	## Calculate the "where clause" and lists of keys and values
	## needed by the SQL statements to support the FixedKeys featue.

	$this->{FixedKeyValsWhereClause} = 
		(keys %{$this->{FixedKeys}}
		 ? join(" AND ", ('', (map 
							   {"$_ = " . $dbh->quote($this->{FixedKeys}->{$_})} 
							                         keys   %{$this->{FixedKeys}})))                         
		 : '');
	
	$this->{FixedKeyValsKeyList  }	 = 
		(keys %{$this->{FixedKeys}} 
		 ? join(", ",    ('', (                      keys   %{$this->{FixedKeys}}))) 
		 : '');
	
	$this->{FixedKeyValsValueList}	 = 
		(keys %{$this->{FixedKeys}}
		 ? join(", ",    ('', (map {$dbh->quote($_)} values %{$this->{FixedKeys}}))) 
		 : '');
	
	## Calculate a list of fields to be returned if in multi-value
	## mode.  This list is either specified in the RetrieveFields
	## parameter, or we use "*", meaning all fields, including keys.

	$this->{RetrieveMultiFieldList}  = 
		(@{$this->{RetrieveFields}} 
		 ? join(", ", @{$this->{RetrieveFields}}) 
		 : '*');

	## If we're in CacheOneTime mode, we cache all the data now by
	## calling FIRSTKEY; in this mode it will never be cached or
	## retrieved again unless a STORE is done (and then only that
	## record).

	$this->FIRSTKEY() if ($this->{CacheMode} eq 'CacheOneTime');

	$Success = 1;			 
										 
  done:
	return($Success);
}

##########  HASH METHODS... these allow this object to be tied to a hash

sub TIEHASH
{
	my $self = shift;
	return($self->new(@_));
}

### FETCH

### Normal mode of operation is to fetch a single value from the hash.

### $All mode is for internal use when caching and means to get all
### values (for all keys) into an anonymous list.

### $NoCache mode is for internal use by STORE when it FETCHes values
### back from the database in order to replenish any cached values for
### records it has just modified.

sub FETCH
{
	my $this = shift;
	my ($KeyName, $All, $NoCache) = @_;

	my $dbh = $this->{_dbh};
	my $sth;
	
	my $ReturnValue;

	## On a regular query, look in the cache before trying the query.
	if ($this->{_CacheHash} && !$All && !$NoCache)
	{
		$ReturnValue = $this->{_CacheHash}->{$KeyName};
		goto done;
	}

	## Ask for one or all entries...

	my $WhereClause = ($All ? "1" : "$this->{KeyField} = '$KeyName'");

	my $SelectClause = $this->{ValueField} || $this->{RetrieveMultiFieldList} || '*';
	
	carp("Fatal error (@{[$dbh->errstr]}) searching for entry \"$KeyName\" in table $this->{TableName}"),
	goto done
		unless 
			(($sth = $dbh->prepare(qq{SELECT $SelectClause FROM $this->{TableName} 
									  WHERE $WhereClause $this->{FixedKeyValsWhereClause} ORDER BY $this->{KeyField}})) && 
			 $sth->execute());

	## Retrieve one or all of the rows, as needed.

	my $RowValues = [];
	while ($All || (@$RowValues < 1))
	{
		my ($ResultHash) = ($sth->fetchrow_hashref());
		
		last unless $ResultHash;	## If in all mode, we stop the loop

		$this->FixUpRetrieval($ResultHash);
		
		## Return either a single value, or a hash of all values if we're
		## in multi-value mode.
		
		my $ThisValue = ($this->{ValueField} 
						 ? $ResultHash->{$this->{ValueField}} 
						 : $ResultHash);
		
		push @$RowValues, $ThisValue;
	}

	## Return the first and only row retrieved, unless in All mode, in
	## which case return an array of all rows retrieved.

	$ReturnValue = ($All ? $RowValues : $RowValues->[0]);

  done:
	$sth->finish() if $sth;
	return($ReturnValue);
}

sub STORE
{
	my $this = shift;
	my ($KeyName, $Value) = @_;
	my $Success = 0;

	my $dbh = $this->{_dbh};
	my $sth;
	my $TablesLocked = 0;
	
	## Prepare a hash mapping field names to values to be stored.
	my ($ValuesHash) = $this->PrepToStore($Value);

	## Optimization: if we're called in multi-key mode and asked to
	## store an empty record, we don't.  This would typically happen
	## if someone tried to dereference a hashref from a failed lookup;
	## perl tries to make it spring into existence by storing an empty
	## value there, and we don't need to do that.

	goto done if ((!$this->{ValueField}) && !keys(%$ValuesHash));

	## If there are still no non-key fields to store, we carp and
	## refuse.

	carp("No non-key fields supplied to store: " . &Dumper($Value)), goto done unless keys(%$ValuesHash);


	## Lock the tables so nobody messes with our update.
	carp("Failed ($dbh->errstr) while locking $this->{TableName} table " . 
		 "creating index entry for $KeyName"), goto done
			 unless 
				 $dbh->do(qq{LOCK TABLES $this->{TableName} WRITE});
	$TablesLocked = 1;
	
	## First see whether this index entry already exists.
	carp("Fatal error (@{[$dbh->errstr]}) searching for entry \"$KeyName\""),
	goto done
		unless 
			(($sth = $dbh->prepare(qq{SELECT $this->{KeyField} FROM $this->{TableName} 
									  WHERE $this->{KeyField} = '$KeyName' $this->{FixedKeyValsWhereClause}})) && 
			 $sth->execute());
	my ($Existing) = $sth->fetchrow_array();
	

	## Then, either insert or update as appropriate.
	if ($Existing)
	{
		## Exists, so replace it.

		my $UpdateFieldsEqualValues = join(", ", map {"$_ = " . $dbh->quote($ValuesHash->{$_})} keys %$ValuesHash);

		carp("Fatal error (@{[$dbh->errstr]}) updating existing $this->{TableName} entry for key \"$KeyName\""), goto done
			unless 
				(($sth = $dbh->prepare
				  (qq{UPDATE $this->{TableName} SET $UpdateFieldsEqualValues 
						  WHERE $this->{KeyField} = '$KeyName' $this->{FixedKeyValsWhereClause}})) &&
				 $sth->execute());
	}
	else
	{
		## Does not exist, so insert it.

		my $InsertFieldNames = join(", ",                                        keys %$ValuesHash);
		my $InsertValueNames = join(", ", map {$dbh->quote($ValuesHash->{$_})}   keys %$ValuesHash);
		my $Length = length ($InsertValueNames);

		carp("Fatal error (@{[$dbh->errstr]}) creating new \"$KeyName\" entry (length < $Length)) for table $this->{TableName}"), 
		goto done
			unless 
				(($sth = $dbh->prepare(qq{INSERT INTO $this->{TableName} ($this->{KeyField}, $InsertFieldNames $this->{FixedKeyValsKeyList}) 
											  VALUES                     ('$KeyName',        $InsertValueNames $this->{FixedKeyValsValueList})})) &&
				 $sth->execute());
	}

	## Now fetch the value back out of the database into the cache, if appropriate.
	$this->{_CacheHash}->{$KeyName} = $this->FETCH($KeyName, !'All', 'NoCache') if $this->{_CacheHash};

	$Success = 1;

  done:
	$dbh->do(qq{UNLOCK TABLES}) if $TablesLocked;
	$sth->finish() if $sth;
	return($Success);
}

sub EXISTS
{
	my $this = shift;
	my ($KeyName) = @_;

	my $dbh = $this->{_dbh};
	my $sth;
	
	## Check the cache if available.
	return(exists($this->{_CacheHash}->{$KeyName})) if $this->{_CacheHash};

	## First see whether this index entry already exists.

	carp("Fatal error (@{[$dbh->errstr]}) searching for entry \"$KeyName\""),
	goto done
		unless 
			(($sth = $dbh->prepare(qq{SELECT $this->{KeyField} FROM $this->{TableName} 
									  WHERE $this->{KeyField} = '$KeyName' $this->{FixedKeyValsWhereClause}})) && 
			 $sth->execute());
	my ($Result) = $sth->fetchrow_array();
	
  done:
	$sth->finish() if $sth;
	return(!!$Result);
}

sub DELETE
{
	my $this = shift;
	my ($KeyName) = @_;

	my $dbh = $this->{_dbh};
	my $sth;

	## First retrieve any existing entry so it can be returned to the
	## caller before being deleted.

	my $DeletedVal = $this->FETCH($KeyName);

	## Delete from the database
	carp("Fatal error (@{[$dbh->errstr]}) deleting entry \"$KeyName\" from $this->{TableName}"),
	pgoto done
		unless 
			(($sth = $dbh->prepare(qq{DELETE FROM $this->{TableName} 
									  WHERE $this->{KeyField} = '$KeyName' $this->{FixedKeyValsWhereClause}})) && 
			 $sth->execute());
	
	## Delete from the cache
	delete $this->{_CacheHash}->{$KeyName} if $this->{_CacheHash};

  done:
	$sth->finish() if $sth;
	return($DeletedVal);
}

sub CLEAR
{
	my $this = shift;

	my $dbh = $this->{_dbh};
	my $sth;
	
	$this->{_CacheHash} = undef;
	
	carp("Fatal error (@{[$dbh->errstr]}) clearing all from \"$this->{TableName}\""),
	goto done
		unless 
			(($sth = $dbh->prepare(qq{DELETE FROM $this->{TableName} 
									  WHERE 1 $this->{FixedKeyValsWhereClause}})) && 
			 $sth->execute());
	
  done:
	$sth->finish() if $sth;
}

### FIRSTKEY

### Gets and hangs on to a full list of all keys in KeyField.  If
### they're long or there are lots of them, this could be a problem.

### To Do: Consider in the future only updating the query to get the
### {_Keys} list on FIRSTKEY only if the mod date of the table has not
### changed since the Keys were last gotten. (Can you check the mod
### date of a table in msyql?  Don't think so, but if you could....)

sub FIRSTKEY
{
	my $this = shift;

	my $dbh = $this->{_dbh};
	my $sth;
	
	my $TablesLocked = 0;

	$this->{_KeyNum} = 0;	## Reset the key counter to zero.

	## If we're in CacheOneTime mode, we're done.  We never
	## recalculate the keys or the values using a database query.

	goto done if ($this->{_CacheHash} && ($this->{CacheMode} eq 'CacheOneTime'));


	## If in (any of the) cache mode(s), we need to lock for read so
	## the query we do here to get the keys matches the big FETCH
	## we're about to do to get the corresponding values.  Sure
	## wouldn't want them to stop corresponding, or our cache would be
	## full of junk.

	if (defined($this->{CacheMode}) && $this->{CacheMode} ne "CacheNone")
	{
		carp("Failed ($dbh->errstr) while locking $this->{TableName} table for caching"), 
		goto done
			unless 
				$dbh->do(qq{LOCK TABLES $this->{TableName} READ});
		$TablesLocked = 1;
	}

	## Ready to get all the keys.  Empty out the list and then get it from the database.

	$this->{_Keys} = [];

	carp("Fatal error (@{[$dbh->errstr]}) searching for first entry"),
	goto done
		unless 
			(($sth = $dbh->prepare(qq{SELECT $this->{KeyField} FROM $this->{TableName} 
									  WHERE 1 $this->{FixedKeyValsWhereClause} ORDER BY $this->{KeyField}})) && 
			 $sth->execute());
	$this->{_Keys} = [map {($sth->fetchrow_array())[0]} (1..$sth->rows())];
	
	## If in (any of the) cache mode(s), we now need to cache all
	## values as well as all keys.  We do this by calling the standard
	## FETCH method, but in our special "All" mode.  It retrieves all
	## values at once with just a single query and returns them in a
	## list whose elements can be indexed by _KeyNum, just as the
	## _Keys list is.  Then we make a _CacheHash object mapping all
	## the keys in _Keys to the retrieved values.

	if (defined($this->{CacheMode}) && $this->{CacheMode} ne "CacheNone")
	{
		$this->{_CacheHash} = {};  
		@{$this->{_CacheHash}}{@{$this->{_Keys}}} = @{$this->FETCH(undef, 'All')};
	}

  done:
	$dbh->do(qq{UNLOCK TABLES}) if $TablesLocked;
	$sth->finish() if $sth;
	return($this->{_Keys}->[$this->{_KeyNum}]);
}

sub NEXTKEY
{
	my $this = shift;
	return($this->{_Keys}->[++$this->{_KeyNum}]);
}

sub DESTROY
{
	my $this = shift;

  done:
	$this->Disconnect();
}

############ OTHER INTERNAL, OVERRIDABLE METHODS...


### PrepToStore

### Constructs a hash mapping field name to Value for all values that
### can/should be stored in response to a storage request.

### This method could be subclassed if the values are to be somehow
### encoded or otherwise manipulated before storage (e.g. serialized,
### encrypted, etc), in which case FixUpRetrieval should also be
### subclassed.

sub PrepToStore
{
	my $this = shift;
	my ($Value) = @_;

	my $dbh = $this->{_dbh};
	
	## In single-value mode, we're just storing one value, $Value, into one field.

	## In multi-value mode, we're presumably given a hash of key-value
	## pairs.  We COPY it so we can non-destructively delete any key
	## fields for safety before trying to store.

	my $ValuesHash = ($this->{ValueField} 
					  ? {$this->{ValueField} => $Value} 
					  : ((ref($Value) eq 'HASH') 
						 ? {%$Value} 
						 : {}));	## Should not happen; return empty hash for safety.
	
	## Remove any key fields; don't want to be setting those.
	delete @$ValuesHash{$this->{KeyField}, keys %{$this->{FixedKeys}}};

	## Any field/value pairs remaining in $ValuesHash at this point
	## are what will get stored into the appropriate record.

  done:
	return($ValuesHash);
}

### FixUpRetrieval

### This is called after values have been retrieved from the database
### but before they are returned to the user.

### Here's where a subclassed method could decrypt, decode,
### deserialize, /validate, etc. any values that were stored, before
### they are returned to the user.  In the base class, there's nothing
### to do because we just allow all fields to be returned as strings.

sub FixUpRetrieval
{
	my $this = shift;
	my ($ValuesHash) = @_;

  done:
	return(1);
}



### Connect
### Disconnect

### ... to and from the database.

sub Connect
{
	my $this = shift;
	my $Success = 0;
	
	carp("Could not open database \"$this->{Database}\".  Please contact administrator.\n"), 
	goto done
		unless
			($this->{_dbh} = DBI->connect(
										  join (":", 
												'DBI', 
												$this->{DBIDriver},
												$this->{Database},
												($this->{HostName} ? $this->{HostName} : ()),
												($this->{Port} ? 	 $this->{Port} : ()),
												),
										  $this->{Login}, $this->{Password}));
	$Success = 1;
  done:	
	return($Success);
}

sub Disconnect
{
	my $this = shift;

	$this->{_dbh}->disconnect() if $this->{_dbh};
}


############# General-purpose SQL table object utility methods; these
############# can be used in situations where the tie() interface is
############# not used.


sub InsertRecordIntoTable
{
	my $this = shift;
	my ($Fields, $Replace, $TableName) = @_;
	my ($Success) = (0);

	my $dbh = $this->{_dbh};
	my $sth;

	$TableName ||= $this->{TableName};

	goto done unless defined($TableName) && length($TableName);
	goto done unless defined($Fields) && $Fields && keys %$Fields;

	my $FieldsList = join(", ", keys %$Fields);
	my $ValuesList = join(", ", map {$dbh->quote($_)} values %$Fields);

	my $ReplaceOrInsert = ($Replace ? 'replace' : 'insert');

	carp("Fatal error (@{[$dbh->errstr]}) creating new entry in table $TableName (@{[%$Fields]})"),
	goto done
		unless
			($dbh->do
			 (qq{$ReplaceOrInsert into $TableName ($FieldsList) values ($ValuesList)}));

	$Success = 1;

  done:
	return($Success);
}

### ReplaceOrInsertIntoTable

### Same as the above, but does a "replace into" instead of "insert
### into".  Most of the time, this is what is wanted.

sub ReplaceOrInsertIntoTable
{
	my $this = shift;
	my ($Fields, $TableName) = @_;
	return($this->InsertRecordIntoTable($Fields, 'Replace', $TableName));
}

sub UpdateFieldsInRecord
{
	my $this = shift;
	my ($SearchFields, $ReplaceFields, $TableName) = @_;
	my ($Success) = (0);

	my $dbh = $this->{_dbh};
	my $sth;

	$TableName ||= $this->{TableName};

	goto done unless defined($TableName)	&& length($TableName);
	goto done unless defined($SearchFields)			&& $SearchFields  && keys %$SearchFields;
	goto done unless defined($ReplaceFields)		&& $ReplaceFields && keys %$ReplaceFields;
	
	my $WhereClause = join(' AND ', (map {"$_ = @{[$dbh->quote($SearchFields ->{$_})]}"} keys %$SearchFields ));
	my $SetClause	= join(', '   , (map {"$_ = @{[$dbh->quote($ReplaceFields->{$_})]}"} keys %$ReplaceFields));
	
	carp("Fatal error (@{[$dbh->errstr]}) updating fields (@{[keys %$ReplaceFields]}) in table $TableName"),
	goto done
		unless
			($dbh->do
			 (qq{update $TableName set $SetClause where $WhereClause}));
	
	$Success = 1;
  done:
	return($Success);
}

sub DoCustomQuery
{
	my $this = shift;
	my ($SearchSpec, $TableName, $QueryString) = @_;
	my ($FoundItems) = [];

	my $dbh = $this->{_dbh};
	my $sth;

	$SearchSpec ||= {};
	$TableName	||= $this->{TableName};

	goto done unless defined($TableName) && length($TableName);
	goto done unless $QueryString;

	## We convert pseudo-variables inside the QueryString (notated as
	## $VarName), by looking up their values in $SearchSpec, and
	## dbh-quoting it.

	## Example: 'select * from People where LastName = $LastName'
	
	$QueryString =~ s{\$(\w+)}{$dbh->quote($SearchSpec->{$1})}ges;
	
	carp("Fatal error executing \"$QueryString\""),
	goto done
		unless
			(($sth = $dbh->prepare
			  ($QueryString)) &&
			 ($sth->execute()));
	
	my $Fields;
	while ($Fields = $sth->fetchrow_hashref())
	{
		push @$FoundItems, $Fields;
	}
	
  done:
	$sth->finish() if $sth;
	## die &Dumper($FoundItems);
	return($FoundItems);
}
sub GetMatchingRecordsFromTable
{
	my $this = shift;
	my ($SearchSpec, $TableName) = (@_);
	my ($FoundItems) = [];

	my $dbh = $this->{_dbh};
	my $sth;

	$SearchSpec	||= {};
	$TableName	||= $this->{TableName};

	goto done unless defined($TableName) && length($TableName);
	
	my $WhereClause = (keys %$SearchSpec ? 
					   "where " . join (' AND ', (map {"$_ = @{[$dbh->quote($SearchSpec->{$_})]}"} 
												  keys %$SearchSpec)) : 
					   '');
	
	carp("Fatal error (@{[$dbh->errstr]}) finding field from \"$TableName\" $WhereClause"),
	goto done
		unless
			(($sth = $dbh->prepare
			  (qq{select * from $TableName $WhereClause})) &&
			 ($sth->execute()));
	
	my $Fields;
	while ($Fields = $sth->fetchrow_hashref())
	{
		push @$FoundItems, $Fields;
	}
	
  done:
	$sth->finish() if $sth;
	return($FoundItems);
}

sub DeleteMatchingRecordsFromTable
{
	my $this = shift;
	my ($SearchSpec, $TableName) = @_;
	my ($Success);

	my $dbh = $this->{_dbh};
	my $sth;

	$SearchSpec	||= {};
	$TableName	||= $this->{TableName};

	goto done unless defined($TableName) && length($TableName);
	
	my $WhereClause = (keys %$SearchSpec ? 
					   "where " . join (' AND ', (map {"$_ = @{[$dbh->quote($SearchSpec->{$_})]}"} 
												  keys %$SearchSpec)) : 
					   '');
	
	carp("Fatal error (@{[$dbh->errstr]}) finding field from \"$TableName\" $WhereClause"),
	goto done
		unless
			(($sth = $dbh->prepare
			  (qq{delete from $TableName $WhereClause})) &&
			 ($sth->execute()));
	
	$Success = 1;
  done:
	$sth->finish() if $sth;
	return($Success);
}

sub SearchWithSingleJoin
{
    my $this = shift;
    my ($TableName, $SearchSpec, $JoinTable, $JoinFields, $JoinRetrieveFields) = (@_);
    my ($FoundItems) = [];

    my $dbh = $this->{_dbh};
    my $sth;

    my $ErrorMessage = "";

    goto done unless defined($TableName) && length($TableName);

    my $TableSpec = ($JoinTable ? "$TableName." : '');

    my $JoinClauses = [($JoinTable && $JoinFields && @{$JoinFields ||= []} ?
                        (map {"$TableName.$_ = $JoinTable.$_"} @$JoinFields) :
                        ())];

    my $WhereClause = ((keys %$SearchSpec) || (@$JoinClauses) ?
                       "where " . join (' AND ', (@$JoinClauses, (map {"$TableSpec$_ @{[$SearchSpec->{$_} =~ s/^([=<>]+)// ? $1 : '=']} @{[$dbh->quote($SearchSpec->{$_})]}"}
                                                                  keys %$SearchSpec))) :
                       '');

    my $SelectSpec = ($JoinTable ? join(", ", "$TableName.*", map {"$JoinTable.$_"} @{$JoinRetrieveFields || []}) : "*");

    my $FromSpec   = ($JoinTable ? "$TableName, $JoinTable" : "$TableName");

    $TableName = "$TableName, $JoinTable" if $JoinTable;

    my $Query = qq{select $SelectSpec from $FromSpec $WhereClause};

    $ErrorMessage = "Fatal error (@{[$dbh->errstr]}) finding field from $FromSpec $WhereClause",
    goto done
        unless
            (($sth = $dbh->prepare
              ($Query)) &&
             ($sth->execute()));

    my $FoundRecord;
    while ($FoundRecord = $sth->fetchrow_hashref())
    {
        push @$FoundItems, $FoundRecord;
    }

  done:
    $sth->finish() if $sth;
    return($FoundItems, $ErrorMessage);
}
1;
