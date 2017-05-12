package CAM::SQLObject;


=head1 NAME

CAM::SQLObject - Object parent class for SQL delegates

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 COMPARISON

This is one of many modules that tries to apply an Object-Oriented
front on SQL database content.  The primary thing that's special about
it is that the helper module, CAM::SQLManager, has a slick way of
encapsulating the SQL so your Perl code has no SQL in it.

The advantage of externalizing your SQL is like the advantage of
externalizing HTML content via templating systems.  You can work on
them separately and you don't need your programmer to also be a DBA.
Having the SQL be separate also lets you easily test and optimize your
queries separately from the main program logic.  Very handy.  See
CAM::SQLManager for more info.

=head1 SYNOPSIS

    package Foo;
    use CAM::SQLObject;
    our @ISA = qw(CAM::SQLObject);
    
    sub sqlcmd { return "foo.xml" }
    sub keyName { return "foo_id" }
    sub insertQueryName { return "add" }
    [ ... other specific changes for this package ... ]
    
    sub renderfoo_name {
      my ($self) = @_;
      return "NAME: " . $self->getfoo_name();
    }
    
    sub getfoo_name {
      my ($self) = @_;
      return $self->{fields}->{foo_name};
    }
    
    sub setfoo_name {
      my ($self, $value) = @_;
      $self->{fields}->{foo_name} = $value;
    }
    
    sub setfoo_id {
      my ($self, $value) = @_;
      $self->{fields}->{foo_id} = $value;
      $self->{keyvalue} = $value;
    }

=head1 DESCRIPTION

This class is not meant to be instantiated directly.  Instead, it is
intended to be the superclass of real database frontend objects.
Those objects will typically add several get<field> and set<field>
routines to act as accessors and mutators for the database fields.

=cut

require 5.005_62;
use strict;
use warnings;
use Carp;
use CAM::SQLManager;

our @ISA = qw();
our $VERSION = '1.01';
our $AUTOLOAD;

#----------------

=head1 CLASS METHODS

=over 4

=cut

#----------------

=item AUTOLOAD

If you call a method on this class that does not exist, the AUTOLOAD
function takes over.  The CAM::SQLObject autoloader handles a few
specialized dynamic methods:

If that method name looks like one of:

   $obj->set<field>(...)
   $obj->get<field>(...)
   $obj->render<field>(...)

then AUTOLOAD implements the appropriate call of the following:

   $obj->set(<field>, ...)
   $obj->get(<field>, ...)
   $obj->render(<field>, ...)

If a subclass overrides a particular get, set, or render method, then
that one will be used.  The SYNOPSIS above shows how to write an
override method.

Special case: If the field starts with C<Table_>, then that is
replaced with the tableName() value plus and underscore.  If the class
does not define the table name, then the method will fail and a
warning will be emitted.


If the method name looks like:

   $pkg->retrieve<query>(...)

then AUTOLOAD implements a call to:

   $pkg->retrieve(<query>, ...)

which can be overloaded in ways similar to the object methods above.

Note that get(), set() and render() are instance methods while
retrieve() is a class method.

=cut

sub AUTOLOAD
{
   my ($func) = $AUTOLOAD =~ /([^:]+)$/;
   return if ($func eq "DESTROY");
   
   # Use default accessor/mutator
   if ($func =~ /^(get|render|set)(Table_)?(.+)$/)
   {
      my $type = $1;
      my $table = $2;
      my $field = $3;
      my $self = $_[0];
      if ($self && ref($self))
      {
         if ($table)
         {
            my $tablename = $self->{tablename};
            if (!$tablename)
            {
               &carp("Undefined tablename in $AUTOLOAD");
               return undef;
            }
            $field = $tablename."_".$field;
         }
         my $pkg = ref($self);
         if ($type eq "get")
         {
            eval 'sub '.$pkg.'::get'.$field.'{shift()->{fields}->{"'.$field.'"}}';
            return $self->get($field);
         }
         elsif ($type eq "set")
         {
            eval 'sub '.$pkg.'::set'.$field.'{shift()->set("'.$field.'",@_)}';
            return $self->set($field, $_[1]);
         }
         elsif ($type eq "render")
         {
            eval 'sub '.$pkg.'::render'.$field.'{my$v=shift()->get'.$field.'();defined $v?$v:""}';
            return $self->render($field);
         }
      }
   }

   # Use default object retrieval method
   elsif ($func =~ /^(retrieve)(.+)$/)
   {
      my $type = $1;
      my $queryname = $2;
      my $pkg = $_[0];
      if ($pkg)
      {
         if ($type eq "retrieve")
         {
            eval 'sub '.$pkg.'::retrieve'.$queryname.'{shift()->retrieve("'.$queryname.'", @_)}';
            return $pkg->retrieve($queryname, @_[1..$#_]);
         }         
      }
   }
   &carp("Undefined function $AUTOLOAD");
}
#----------------

=item new

Creates a new stub object.  

The following documenation is DEPRECATED as of version 0.50.  New
subclasses should instead override individual functions instead of
changing the new() method.

Subclasses should consider overriding the
following fields, in order of priority:

  Name         Default   Purpose
  ----         -------   -------
  sqlcmd       undef     location of the SQL templates (see SQLManager)
  keyname      undef     name of the primary key field (needed for save())
  tablename    undef     name of the SQL table (needed for fieldNames())
  update_name  "update"  name of query in sqlcmd (needed for save())
  insert_name  "insert"  name of query in sqlcmd (needed for save())
  delete_name  "delete"  name of query in sqlcmd
  keygen       undef     which technique should be used to get new keys
  keygen_data  undef     info needed for how to generate keys

See newkey() below for more information on keygen and keygen_data.

=cut

sub new
{
   my $pkg = shift;

   my @sqlcmds = $pkg->sqlcmd();
   my $self = {
      keyname => $pkg->keyName(),
      keyvalue => undef,
      sqlcmd => $sqlcmds[0],
      sqlcmds => [@sqlcmds],
      tablename => $pkg->tableName(),
      update_name => $pkg->updateQueryName(),
      insert_name => $pkg->insertQueryName(),
      delete_name => $pkg->deleteQueryName(),
      keygen => $pkg->keygenAlgorithm(),
      keygen_data => $pkg->keygenData,
      fields => {},
   };
   return bless($self, $pkg);
}
#----------------

=item getMgr

Retrieves a CAM::SQLManager instance for this class.  This can be
called as a class method or as an instance method.

=cut

sub getMgr
{
   my $pkg_or_self = shift;

   my @args = ();
   my $dbh = $pkg_or_self->_getDBH();
   push @args, "-dbh" => $dbh if ($dbh);

   my $mgr;
   if (ref $pkg_or_self)
   {
      my $self = $pkg_or_self;
      $self->{lastmgr} ||= CAM::SQLManager->getMgr(@args, $self->_getCmds());
      $mgr = $self->{lastmgr};
   }
   else
   {
      my $pkg = $pkg_or_self;
      $mgr = CAM::SQLManager->getMgr(@args, $pkg->_getCmds());
   }

   return $mgr;
}
#----------------

# Internal method, default for super class.  Sub classes get
# overridden ONLY in setDBH()

sub _getDBH
{
   my $pkg_or_self = shift;
   return undef;
}
#----------------

=item setDBH DBH

Tells the SQL manager to use the specified database handle for all
interaction with objects of this class.  If setDBH() is not called,
the default database handle from CAM::SQLManager is used.  This method
must be called before any objects are instantiated.

=cut

sub setDBH
{
   my $pkg_or_self = shift;
   my $dbh = shift;
   
   my $pkg = ref($pkg_or_self) || $pkg_or_self;
   no warnings; # block the "function redefined" warning message
   eval "*".$pkg."::_getDBH = sub{return \$dbh};";
}
#----------------

=item retrieveByKey KEYVALUE

Class method to retrieve a single object for the specified key.
Objects with complicated SQL representations should override this
method.

This method executes an implicit query that looks like:

  select * from <table> where <keyname>=<keyvalue>

=cut

sub retrieveByKey
{
   my $pkg = shift;
   my $keyValue = shift;

   return undef if (!$keyValue);

   my $self = $pkg->new();
   my $mgr = $self->getMgr();
   my $tableName = $self->{tablename};
   my $keyName = $self->{keyname};
   return undef if (!($mgr && $tableName && $keyName));

   my $dbh = $mgr->{dbh};
   my $sth = $dbh->prepare("select * from $tableName " .
                           "where $keyName=" . $dbh->quote($keyValue));

   # Use intimate knowledge of SQLManager internals to time this query
   $mgr->_startclock() if ($CAM::SQLManager::global_benchmarking);

   $sth->execute();

   $mgr->_stopclock() if ($CAM::SQLManager::global_benchmarking);
   $mgr->_incrStats("retrieveByKey") if ($CAM::SQLManager::global_benchmarking);

   my $row = $sth->fetchrow_hashref();
   $sth->finish();

   return undef if (!$row);

   no strict 'refs';
   foreach my $fieldName (keys %$row)
   {
      my $function = "set$fieldName";
      $self->$function($row->{$fieldName});
   }
   return $self;
}
#----------------

=item retrieve QUERYNAME, [KEY => VALUE, KEY => VALUE, ...]

Generic class method to retrieve objects from a specified query.  The
extra parameters are passed as bind variables to the query.  This is
pretty much just a handy wrapper around the CAM::SQLManager method
retrieveObjects().

In scalar context, just the first object will be returned.  In array
context, all of the matching objects are returned.

Recommended usage: Use this via the autoloaded method
retrieve<queryname>().  For example, if you have a query
"GetOldClients" which takes "year" as a query parameter, then call it
like:

    @clients = CAM::SQLObject->retrieveGetOldClients(year => "1998");

instead of

    @clients = CAM::SQLObject->retrieve("GetOldClients", year => "1998");

The former example has the advantage that subclasses can easily
override it to do different and interesting things.

=cut

sub retrieve
{
   my $pkg_or_self = shift;
   my $queryname = shift;

   my $mgr = $pkg_or_self->getMgr();
   return wantarray ? () : undef if (!$mgr);
   my @results;
   if (ref($pkg_or_self))
   {
      my $self = $pkg_or_self;
      my $pkg = ref($self);
      @results = $mgr->retrieveObjects($queryname, $pkg, [],
                                       $self->getAllFields(), @_);
   }
   else
   {
      my $pkg = $pkg_or_self;
      @results = $mgr->retrieveObjects($queryname, $pkg, [], @_);
   }
   return wantarray ? @results : $results[0];
}
#----------------

=back

=head1 OVERRIDE METHODS

The following methods are all class or instance methods.  Subclasses
are encouraged to override them for more specific functionality.

=over 4

=cut

#----------------

=item sqlcmd

This class or instance method returns the name of the XML file used to
hold SQL commands.  Subclasses have the following options:

    - override the new() method to explicitly set the sqlcmd parameter
      (this is the old style and is deprecated, since it did not work
      as a class method)
    - override the sqlcmd() method to specify the file
      (recommended for unusual file names)
    - let CAM::SQLObject try to find the file

With the latter option, this method will search in the following
places for the sqlcmd file (in this order):

    - use the package name, replacing '::' with '/' (e.g. Foo::Bar
      becomes $sqldir/Foo/Bar.xml)
    - use the trailing component of the package name (e.g. Foo::Bar
      becomes $sqldir/Bar.xml)

Subclasses which are happy to use these default file names should not
override this method, or change the sqlcmd proprty of any instances.
Otherwise, this method should either be overridden by all subclasses
(which is the recommended style), or those subclasses should override
the new() method to set the sqlcmd field explicitly (which is the
previous, now deprecated, style).

Here is a simple example override method:

     sub sqlcmd { return "foobar.xml"; }

=cut

sub sqlcmd
{
   my $pkg_or_self = shift;

   my $pkg = ref($pkg_or_self) || $pkg_or_self;
   my $self = ref($pkg_or_self) ? $pkg_or_self : undef;

   my @files = ();
   if ($self && $self->{sqlcmd})
   {
      push @files, $self->{sqlcmd};
   }

   my $fullpath = $pkg;
   $fullpath =~s/\:\:/\//g;
   $fullpath .= ".xml";
   push @files, $fullpath;

   my $shortpath = $fullpath;
   $shortpath =~ s/^.*\///;
   push @files, $shortpath;

   return wantarray ? @files : $files[0];
}
#----------------

=item keyName

Returns the name of the primary key field (needed for save() and
retrieveByKey()).  This default method returns the primary key name
from the SQL Manager's XML file, or undef.

=cut

sub keyName
{
   my $pkg_or_self = shift;

   my $mgr = $pkg_or_self->getMgr();
   if ($mgr)
   {
      return $mgr->keyName() || undef;
   }
   return undef;
}
#----------------

=item tableName

Returns the name of the SQL table (needed for fieldNames() and
retrieveByKey()).  This default method returns the table name from the
SQL Manager's XML file, or undef.

=cut

sub tableName
{
   my $pkg_or_self = shift;

   my $mgr = $pkg_or_self->getMgr();
   if ($mgr)
   {
      return $mgr->tableName() || undef;
   }
   return undef;
}
#----------------

=item updateQueryName

Returns the name of the default query to do record updates in SQL XML
file (needed for save()).  This default method returns "update".

=cut

sub updateQueryName
{
   my $pkg_or_self = shift;

   return "update";
}
#----------------

=item insertQueryName

Returns the name of the default query to do record inserts in SQL XML
file (needed for save()).  This default method returns "insert".

=cut

sub insertQueryName
{
   my $pkg_or_self = shift;

   return "insert";
}
#----------------

=item deleteQueryName

Returns the name of the default query to do record deletes in SQL XML
file.  This default method returns "delete".

=cut

sub deleteQueryName
{
   my $pkg_or_self = shift;

   return "delete";
}
#----------------

=item keygenAlgorithm

Returns the name of the algorithm that the newkey() method uses to
generate its keys.  This default method returns undef.  See newkey()
for more details.

=cut

sub keygenAlgorithm
{
   my $pkg_or_self = shift;

   return undef;
}
#----------------

=item keygenData

Returns the ancillary data needed to support the algorithm specified
by keygenAlgorithm().  The contents of this data depend on the
algorithm chosen.  This default method returns undef.  See newkey()
for more details.

=cut

sub keygenData
{
   my $pkg_or_self = shift;

   return undef;
}
#----------------

=back

=head1 INSTANCE METHODS

=over 4

=cut

#----------------

=item get_key

Retrieve the object key.

=cut

sub get_key
{
   my $self = shift;

   if (!$self->{keyname})
   {
      &carp("No keyname defined");
      return undef;
   }
   no strict 'refs';
   my $function = "get" . $self->{keyname};
   return $self->$function();
}
#----------------

=item set_key

Change the object key.

=cut

sub set_key
{
   my $self = shift;
   my $newkey = shift;

   if (!$self->{keyname})
   {
      &carp("No keyname defined");
      return undef;
   }

   no strict 'refs';
   my $function = "set" . $self->{keyname};
   return $self->$function($newkey);
}
#----------------

=item get FIELD

Retrieve a field.  This method is intended for internal use only,
i.e. from AUTOLOAD or from subclass accessors.  An example of the
latter:

    sub getFOO_ID {
       my $self = shift;
       return $self->get("FOO_ID") + $ID_offset;
    }

=cut

sub get
{
   my $self = shift;
   my $field = shift;

   return $field ? $self->{fields}->{$field} : undef;
}
#----------------

=item render FIELD

Retrieve a field, with output formatting applied.  This method is
intended for internal use only, i.e. from AUTOLOAD or from subclass
accessors.  An example of the latter:

    sub renderFOO_ID {
       my $self = shift;
       return "ID " . &html_escape($self->render("FOO_ID"));
    }

=cut

sub render
{
   my $self = shift;
   my $field = shift;

   no strict 'refs';
   my $function = "get$field";
   my $value = $self->$function();
   $value = "" if (!defined $value);
   return $value;
}
#----------------

=item set FIELD, VALUE [FIELD, VALUE, ...]

Assign a field.  This method is intended for internal use only,
i.e. from AUTOLOAD or from subclass mutators.  An example of the
latter:

    sub setFOO_ID {
       my $self = shift;
       my $value = shift;
       return $self->set("FOO_ID", $value - $ID_offset);
    }

=cut

sub set
{
   my $self = shift;
   # process additional args below

   while (@_ > 0)
   {
      my $field = shift;
      my $value = shift;

      if ($field)
      {
         if ($self->{keyname} && $self->{keyname} eq $field)
         {
            $self->{keyvalue} = $value;
         }
         $self->{fields}->{$field} = $value;
      }
      else
      {
         &carp("Attempt to set undef field");
      }
   }
   return $self;
}
#----------------

=item fill QUERYNAME

Given an object with partially filled fields, run an SQL query that
will retrieve more fields.  The query should be designed to return
just one row.  If any command in the query does not return exactly one
row, the command will fail.

Example:

    $obj = new ACME::Towel;
    $obj->set_serial_number("0123456789");
    $obj->fill("get_towel_by_sn");

=cut

sub fill
{
   my $self = shift;
   my $queryname = shift;

   return $self->_runSelectSQL($queryname, @_);
}
#----------------

=item fieldNames

=item fieldNames TABLENAME

Retrieves an array of the names of the fields in the primary SQL
table.  If TABLENAME is omitted, this applies to the primary table
(this only works if the subclass sets the $self->{tablename}
property).  This function uses some MySQL specific directives...

(Note: this is a kludge in that it runs the "describe <table>" SQL
directly, instead of going through the SQLManager's XML interface)

=cut

sub fieldNames
{
   my $self = shift;
   my $tablename = shift || $self->{tablename};

   if (!$tablename)
   {
      warn "No tablename specified";
      return ();
   }

   my $mgr = $self->getMgr();
   if (!$mgr)
   {
      &carp("Failed to retrieve an SQL manager");
      return ();
   }
   my $sth = $mgr->{dbh}->prepare("describe $tablename");
   return () if (!$sth);
   $sth->execute() or return ();
   my @fieldnames = ();
   while (my $row = $sth->fetchrow_arrayref())
   {
      push @fieldnames, $row->[0];
   }
   return @fieldnames;
}
#----------------

=item query

Run the specified query against this object.  All bound SQL parameters
will be read from this object.  This is applicable to both SELECT as
well as UPDATE/INSERT queries.  While usually called as an instance
method, this can be called as a class method if all you are interested
in is the side effects of the SQL query instead of the data.

NOTE!  This method does not retrieve the results of SELECT statements
into the object.  If you wish to apply SELECT data to your objects,
use either fill() or retrieve().

=cut

sub query
{
   my $pkg_or_self = shift;
   my $queryname = shift;

   return $pkg_or_self->_runSQL($queryname, @_);
}
#----------------

=item save

Either update or insert this object into the database.  The keyname
field must be set so this function can figure out whether to update or
insert.

=cut

sub save
{
   my $self = shift;

   if (!$self->{keyname})
   {
      &carp("No keyname defined");
      return undef;
   }
   if (defined $self->{keyvalue})
   {
      return $self->update();
   }
   else
   {
      return $self->insert();
   }
}
#----------------

=item update

Run the default update SQL template.  This function is usually just
called from the save() function.

=cut

sub update
{
   my $self = shift;
   my $query = shift || $self->{update_name};

   return $self->_runSQL($query);
}
#----------------

=item insert

Run the default insert SQL template.  This function is usually just
called from the save() function.

=cut

sub insert
{
   my $self = shift;
   my $query = shift || $self->{insert_name};

   my $result = $self->_runSQL($query);
   if ($result && $self->{keyname})
   {
      # Retrieve the key.  Store in both places.
      # This is likely dependent on the database.  It works on MySQL
      $self->{keyvalue} = $self->{lastmgr}->getLastInsertID();
      $self->set_key($self->{keyvalue});
   }
   return $result;
}
#----------------

=item delete

Run the default delete SQL template.

=cut

sub delete
{
   my $self = shift;
   my $query = shift || $self->{delete_name};

   return $self->_runSQL($query);
}
#----------------

=item getAllFields

=item allFields  <deprecated>

Returns a hash of all the fields, all retrieved via the accessor
functions.  "allFields" is the old name for this function, and is here
for backward compatibility only.

=cut

sub allFields
{
   my $self = shift;
   return $self->getAllFields(@_);
}

sub getAllFields
{
   my $self = shift;

   my %hash = ();
   no strict 'refs';
   foreach my $key (keys %{$self->{fields}})
   {
      my $function = "get$key";
      $hash{$key} = $self->$function();
   }
   return (%hash);
}
#----------------

=item renderAllFields

Returns a hash of all the fields, retrieved via the render
functions.

=cut

sub renderAllFields
{
   my $self = shift;

   my %hash = ();
   no strict 'refs';
   foreach my $key (keys %{$self->{fields}})
   {
      my $function = "render$key";
      $hash{$key} = $self->$function();
   }
   return (%hash);
}
#----------------

=item newkey

=item newkey KEYGEN, KEYGENDATA

Create a new, unique key.  Note that this key is NOT added to the
object.  This is a wrapper for several different key generation
techniques.  The following techniques are provided:

=over

=cut

sub newkey
{
   my $self = shift;

   my $keygen = defined $_[0] ? shift : $self->{keygen};
   my $data = defined $_[0] ? shift : $self->{keygen_data};

   if (defined $keygen)
   {
      if (ref($keygen))
      {
         if (ref($keygen) eq "CODE")
         {

=item keygen = <reference to function>, keygen_data = <anything>

The specified function is called with keygen_data as its argument.
This function should return the new key.

=cut

            return &$keygen($data);
         }
      }
      else
      {
         # All non-SQL techniques should be first

         # ...

         # All SQL techniques get the database handle from the SQLManager and share this code:

         my $mgr = $self->getMgr();
         my $dbh = $mgr->{dbh};

         if ($keygen eq "query")
         {

=item keygen = query, keygen_data = 'queryname'

The key generation SQL is part of the SQL command template.
<queryname> is run via SQLManager.

=cut

            if (!$data)
            {
               &croak("No SQL template query has been specified");
            }
            my $sth = $mgr->query($data);
            my ($key) = $sth->fetchrow_array();
            $sth->finish();
            return $key;
         }
         elsif ($keygen eq "insertcountertable")
         {

=item keygen = insertcountertable, keygen_data = 'table.keycol,randcol'

Insert into a counter table and retrieve the resulting key.  This
technique uses a random number to distinguish between concurrent
inserts.  This technique does not lock the counter table.  This
technique calls srand() and rand().  Note: this technique assumes that the
keycolumn is an autoincrementing column that des not backtrack upon
deletes.

=cut

            if ((!$data) || $data !~ /^(\w+).(\w+),(\w+)$/)
            {
               &croak("No SQL table and columns specified for $keygen key generation");
            }
            my ($table,$keycol,$randcol) = ($1,$2,$3);
            my $key;
            
            if (!$cache::did_srand)
            {
               srand(time() ^ ($$ + ($$<<15))); # from perl reference book
               $cache::did_srand = 1;
            }
            while (!$key)
            {
               my $rn = rand();
               $dbh->do("INSERT INTO $table SET $randcol=$rn");
               my $sth = $dbh->prepare("SELECT $keycol FROM $table WHERE $randcol=$rn");
               $dbh->do("DELETE FROM $table WHERE $randcol=$rn");
               if ($sth->rows() == 1)
               {
                  my ($key) = $sth->fetchrow_array();
                  $sth->finish();
                  return $key;
               }
            }
         }
         elsif ($keygen eq "lockcountertable")
         {

=item keygen = lockcountertable, keygen_data = 'table.keycol'

Lock the counter table, add one to the counter, retrieve the counter,
unlock the counter table.

=cut

            if ((!$data) || $data !~ /^(\w+).(\w+)$/)
            {
               &croak("No SQL table and column specified for $keygen key generation");
            }
            my ($table,$column) = ($1,$2);
            $dbh->do("LOCK TABLE $table WRITE");
            $dbh->do("UPDATE $table SET $column=$column+1");
            my $sth = $dbh->prepare("SELECT $column FROM $table");
            $sth->execute();
            my ($key) = $sth->fetchrow_array();
            $sth->finish();
            $dbh->do("UNLOCK TABLE");
            return $key;
         }
         elsif ($keygen eq "mysqlcountertable")
         {

=item keygen = mysqlcountertable, keygen_data = 'table.keycol'

Add one to the counter and use MySQL's atomic retrieval to return the
new value of that counter.  This technique does not lock the counter
table.

=cut

            if ((!$data) || $data !~ /^(\w+).(\w+)$/)
            {
               &croak("No SQL table and column specified for $keygen key generation");
            }
            my ($table,$column) = ($1,$2);
            $dbh->do("UPDATE $table SET $column=LAST_INSERT_ID($column+1)");
            my $sth = $dbh->prepare("SELECT LAST_INSERT_ID()");
            $sth->execute();
            my ($key) = $sth->fetchrow_array();
            $sth->finish();
            return $key;
         }
         elsif ($keygen eq "maxcountertable")
         {

=item keygen = maxcountertable, keygen_data = 'table.keycol'

Find the maximum value in the specified column, then add one to get
the new key.  This does not lock, so you may want to lock manually.

=cut

            if ((!$data) || $data !~ /^(\w+).(\w+)$/)
            {
               &croak("No SQL table and column specified for $keygen key generation");
            }
            my ($table,$column) = ($1,$2);
            my $sth = $dbh->prepare("SELECT max($column)+1 FROM $table");
            $sth->execute();
            my ($key) = $sth->fetchrow_array();
            $sth->finish();
            return $key;
         }
      }
   }

=back

=cut

   # Should have returned a key by now
   &croak("No valid key generation technique has been specified");
}

#----------------
# PRIVATE METHOD
# Run a non-select SQL template

sub _runSQL
{
   my $pkg_or_self = shift;
   my $type = shift;

   my $mgr = $pkg_or_self->getMgr();
   if (!$mgr)
   {
      &carp("Failed to retrieve an SQL manager");
      return undef;
   }
   if (ref($pkg_or_self))
   {
      my $self = $pkg_or_self;
      return $mgr->storeObject($type, $self, @_);
   }
   else
   {
      return $mgr->do($type, @_);
   }
}

#----------------
# PRIVATE METHOD
# Run a select SQL template

sub _runSelectSQL
{
   my $self = shift;
   my $type = shift;

   my $mgr = $self->getMgr();
   if (!$mgr)
   {
      &carp("Failed to retrieve an SQL manager");
      return undef;
   }
   return $mgr->fillObject($type, $self, @_);
}

#----------------
# PRIVATE METHOD

sub _getCmds
{
   my $pkg_or_self = shift;

   my @cmds;
   if (ref($pkg_or_self))
   {
      my $self = $pkg_or_self;
      @cmds = grep {$_} $self->{sqlcmd}, @{$self->{sqlcmds} || []};
      shift @cmds if ($cmds[0] && $cmds[1] && $cmds[0] eq $cmds[1]);
   }
   else
   {
      my $pkg = $pkg_or_self;
      @cmds = $pkg->sqlcmd();
      if (! $cmds[0])
      {
         # fall into this block if we are using an old-style subclass
         # that does not override the sqlcmd() class method.
         
         # Kludge: I need a copy of the XMLfile name, so we instantiate a
         # dummy object.  This should have been in a class accessor
         my $dummy = $pkg->new();
         @cmds = $dummy->_getCmds();
      }
   }
   return @cmds;
}

#----------------
# PRIVATE METHOD
# For debugging

sub _lastStatement
{
   my $self = shift;
   return $self->{lastmgr} ? $self->{lastmgr}->{laststatement} : "";
}
sub _lastStatements
{
   my $self = shift;
   return $self->{lastmgr} ? join(";",@{$self->{lastmgr}->{laststatements}}) : "";
}

#----------------
# PRIVATE METHOD
# For debugging

sub _lastBinds
{
   my $self = shift;
   my $lastbinds = $self->{lastmgr} ? $self->{lastmgr}->{lastbinds} : undef;
   return $lastbinds ? @$lastbinds : ();
}
sub _lastBindss
{
   my $self = shift;
   my $lastbinds = $self->{lastmgr} ? $self->{lastmgr}->{lastbindss} : [];
   return join(";", map {join(",", map {defined $_ ? $_ : "(undef)"} @$_)} @$lastbinds);
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=head1 SEE ALSO

CAM::SQLManager
