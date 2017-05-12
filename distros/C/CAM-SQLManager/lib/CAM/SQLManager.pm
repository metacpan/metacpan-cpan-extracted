package CAM::SQLManager;

=head1 NAME

CAM::SQLManager - Encapsulated SQL statements in XML

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

We recommend that you do NOT use CAM::SQLManager directly, but instead
use the more convenient wrapper, CAM::SQLObject.  In that case, you
can skip to the bottom to learn about the XML files.  If you do choose
to use this directly, here's how it goes:

  use CAM::SQLManager;
  use DBI;
  
  my $dbh = DBI->connect(blah blah);
  
  CAM::SQLManager->setDBH($dbh);
  CAM::SQLManager->setDirectory("/var/www/sqlcmds");
  
  my $sql1 = CAM::SQLManager->new("user.xml");
  my $sth = $sql1->query("search", username => "chris");
  
  my $dbh2 = DBI->connect(blah blah);
  my $sql2 = CAM::SQLManager->new(-dbh => $dbh2, -cmd => "product.xml", 
                                  -dir => "/usr/share/sqlcmds");
  my $result = $sql2->do("add", name => "vase", color => "red", price => "50.00");
  
  my $sql3 = CAM::SQLManager->new("product.xml");
  my @towels = $sql3->retrieveObjects("search", "ACME::Towel", [], prodtype => "%towel%");
  
  my $sql4 = CAM::SQLManager->new("product.xml");
  my $towel = ACME::Towel->new();
    [... fill/edit object ...]
  $sql4->storeObject("insert", $towel);

Use these commands for testing the various SQL queries in a CGI script:

  CAM::SQLManager->setDirectory("/var/www/sqlcmds");
  CAM::SQLManager->setDBH($dbh);
  CAM::SQLManager->setBenchmarking(1);  # optional
  CAM::SQLManager->testCommands();

=head1 DESCRIPTION

This package implements SQL templates.  This allows the programmer to
increase the separation between the SQL RDBMS and the Perl programming
logic of any project.  This package has features that make it
particularly useful in a web environment, as it is quite easy to write
a CGI program to allow testing and evalutation of the SQL templates.

=head1 PORTING

As of v1.12, we have added support for non-Unix file systems via
File::Spec.  This is intended to enable Win32 usage of this module.
As of v1.13, this is pretty well tested in production by the authors,
so we think it should work fine for you.

=cut

require 5.005_62;
use strict;
use warnings;
use Carp;
use File::Spec;
use CAM::XML;

our @ISA = qw();
our $VERSION = '1.13';

our $global_directory      = "";
our $global_dbh            = undef;
our @global_extensions     = (".xml");
our %global_cache          = ();
our $global_benchmarking   = 0;  # boolean: should we time the SQL queries?
our $global_safe_functions = 1;  # boolean: faster if false, but may die()
                                 # if true, eval{} is used

our $errstr                = undef;  # (rarely) used to pass error messages

our %global_stats;
&_clearStats();
sub _clearStats
{
   # Any changes to this data structure should be propagated into
   # _incrStats() and the documentation for statistics()
   %global_stats = (
                    queries => 0,
                    time => 0,
                    cmds => {},
                    );
}

#------------------

=head1 FUNCTIONS 

=over 4

=cut

#------------------

=item new [CMD,] [ARG => VALUE, ...]

Open and read an SQL template.  Possible arguments (with example
values) are:

       -cmd => "user.xml"
       -dir => "/some/sql/template/dir"
       -dbh => $dbh   (should be a DBI object)

if -dir or -dbh are not specified, the global values are used (set by
setDirectory and setDBH below).

The file <dir>/<cmd>.xml should exist.

=cut

sub new
{
   my $pkg = shift;

   my $self = bless({
      # user settable parameters:
      cmd => "",
      dbh => undef,
      dir => $global_directory,

      # Internal parameters:
      filename => "",
      filetime => 0,
      tableName => "",
      keyName => "",
      queries => {},
      defaultquery => undef,
   }, $pkg);
   
   # pick up default arguments, if any
   $self->{cmd} = shift if (@_ > 0 && $_[0] !~ /^\-[a-z]+$/);

   # process switched arguments
   while (@_ > 0 && $_[0] =~ /^\-[a-z]+$/)
   {
      my $key = shift;
      my $value = shift;
      $key =~ s/^\-//;
      $self->{$key} = $value;
   }

   if (@_ > 0)
   {
      &carp("Too many arguments");
      return undef;
   }

   # Validate "dbh"
   if (!$self->getDBH()) {
      &carp("The DBH object is undefined");
      return undef;
   }
   if (ref($self->getDBH()) !~ /^DBI\b/ && ref($self->getDBH()) !~ /^DBD\b/) {
      &carp("The DBH object is not a valid DBI/DBD connection: " . ref($self->getDBH()));
      return undef;
   }

   # Validate "cmd"
   if ($self->{cmd} !~ /^(\w+[\/\\])*\w+(|\.\w+)$/)
   {
      &carp("Command keyword is not alphanumeric: $$self{cmd}");
      return undef;
   }

   # Use "dir" and "cmd" to get the SQL template
   $self->{filename} = File::Spec->catfile($self->{dir}, $self->{cmd});
   local *FILE;
   if (!open(FILE, $self->{filename}))
   {
      &carp("Cannot open sql command '$$self{filename}': $!");
      return undef;
   }
   local $/ = undef;
   $self->{sql} = <FILE>;
   close(FILE);

   # Record the last-mod time of the file so we can notice if it changes
   $self->{filetime} = (stat($self->{filename}))[9];

   # Set up the statistics data structures
   if (!exists $global_stats{cmds}->{$self->{cmd}})
   {
      # Any changes to this data structure should be propagated into
      # _incrStats() and the documentation for statistics()
      $global_stats{cmds}->{$self->{cmd}} = {
         queries => 0,
         time => 0,
         query => {},
      };
   }

   my $struct = CAM::XML->parse($self->{sql});

   if ((!$struct) || $struct->{name} ne "sqlxml")
   {
      &carp("XML parsing of the SQL query failed");
      return undef;
   }

   # Read the table data
   my ($tabledata) = $struct->getNodes(-path => "/sqlxml/table");
   if ($tabledata)
   {
      if ($tabledata->getAttribute("name"))
      {
         $self->{tableName} = $tabledata->getAttribute("name");
      }
      if ($tabledata->getAttribute("primarykey"))
      {
         $self->{keyName} = $tabledata->getAttribute("primarykey");
      }
   }

   # Extract all of the queries
   my @queries = $struct->getNodes(-path => "/sqlxml/query");
   if (@queries < 1)
   {
      &carp("There are no query tags in $$self{filename}");
      return undef;
   }
   
   foreach my $query (@queries)
   {
      my $name = $query->getAttribute("name");
      $name = "_default" if (!$name);
      if (exists $self->{queries}->{$name})
      {
         &carp("Multiple queries named $name in $$self{filename}");
         return undef;
      }
      
      # Throw away whitespace elements in the query body
      my $queryarray = [grep({$_->isa("CAM::XML") || $_->{text} =~ /\S/} $query->getChildren())];
      
      $self->{queries}->{$name} = $queryarray;
      if ((!$self->{defaultquery}) || $name eq "_default")
      {
         $self->{defaultquery} = $queryarray;
      }
   }

   # Set up statistics data structure
   foreach my $queryname ("retrieveByKey", keys %{$self->{queries}})
   {
      # Any changes to this data structure should be propagated into
      # _incrStats() and the documentation for statistics()
      $global_stats{cmds}->{$self->{cmd}}->{query}->{$queryname} = {
         queries => 0,
         time => 0,
      };
   }

   return $self;
}


#------------------

=item getMgr CMD, CMD, ...

=item getMgr -dbh => DBH, CMD, CMD, ...

Like new() above, but caches the manager objects for later
re-requests.  Unlike new(), the database handle and SQL file directory
must already be set.  Use this function like:

  CAM::SQLManager->getMgr("foo.xml");

If more than one command is specified, the first one that results in a
real file is used.

=cut

sub getMgr
{
   my $pkg = shift;
   my @args = ();
   if ($_[0] && $_[0] eq "-dbh")
   {
      push @args, shift, shift;
   }
   my @cmds = (@_);

   foreach my $cmd (@cmds)
   {
      if (-e File::Spec->catfile($global_directory, $cmd))
      {
         if (exists $global_cache{$cmd})
         {
            # Check to make sure the SQL file has not changed
            if ($global_cache{$cmd}->{filetime} < (stat($global_cache{$cmd}->{filename}))[9])
            {
               $global_cache{$cmd} = $pkg->new($cmd, @args);
            }
         }
         else
         {
            $global_cache{$cmd} = $pkg->new($cmd, @args);
         }
         return $global_cache{$cmd};
      }
   }
   return undef;
}
#------------------

=item getAllCmds

Search the SQL directory for all command files.  This is mostly just
useful for the testCommands() method.

=cut

sub getAllCmds
{
   my $pkg = shift;

   my @files;
   my $regex = join("|", map {quotemeta} @global_extensions);
   my @dirs = ($global_directory);
   my %seendirs;
   while (@dirs > 0)
   {
      local *DIR;
      my $dir = shift @dirs;
      next if ($seendirs{$dir}++);
      
      if (!opendir(DIR, $dir))
      {
         if ($dir eq $global_directory)
         {
            &carp("Failed to read the SQL library directory '$dir': $!");
            return ();
         }
      }
      else
      {
         my @entries = readdir(DIR);
         closedir(DIR);
         
         @entries = map {File::Spec->catfile($dir, $_)} grep !/^\.\.?$/, @entries;
         push @files, grep /($regex)$/, @entries;
         push @dirs, grep {-d $_} @entries;
      }
   }
   return @files;
}
#------------------

=item setDirectory DIRECTORY

Set the global directory for this package.  Use like this:

  CAM::SQLManager->setDirectory("/var/lib/sql");

=cut

sub setDirectory
{
   my $pkg = shift; # unused
   my $val = shift;

   $global_directory = $val;
   return $pkg;
}
#------------------

=item setDBH DBI-OBJECT

As a class method, this sets the global database handle for this
package.  Use like this:

  CAM::SQLManager->setDBH($dbh);

As an object method, this sets the database handle for just that
instance.

=cut

sub setDBH
{
   my $pkg_or_self = shift;
   my $val = shift;

   if (ref($pkg_or_self))
   {
      my $self = $pkg_or_self;
      $self->{dbh} = $val;
   }
   else
   {
      $global_dbh = $val;
   }
   return $pkg_or_self;
}
#------------------

=item getDBH

Get the current database handle.  If a handle is not specifically set for an instance, the global database handle is returned.

=cut

sub getDBH
{
   my $pkg_or_self = shift;

   my $dbh;

   if (ref($pkg_or_self))
   {
      my $self = $pkg_or_self;
      $dbh = $self->{dbh};
   }
   $dbh ||= $global_dbh;
   return $dbh;
}
#------------------

=item setBenchmarking 0|1

Specify whether to benchmark the SQL queries.  The default is 0 (false).  To retrieve the benchmarking data, use the statistics() method.  Use like this:

  CAM::SQLManager->setBenchmarking(1);

=cut

sub setBenchmarking
{
   my $pkg = shift; # unused
   my $val = shift;

   $global_benchmarking = $val;

   if ($global_benchmarking) {
      eval "use Time::HiRes";
      if ($@)
      {
         &carp("Failed to load the Time::HiRes package, needed for benchmarking");
         $global_benchmarking = 0;
      }
   }

   # Reset
   &_clearStats();

   return $pkg;
}
#------------------

=item validateXML

Warning: this function relies on XML::Xerces.  If XML::Xerces is not
installed, this routine will always indicate that the document is
invalid.

Test the integrity of the XML encapsulation of the SQL statement(s).
Returns true of false to indicate success or failure.  On failure, it
sets $CAM::SQLManager::errstr with an error description.  Succeeds
automatically on a non-XML SQL file.

=cut

sub validateXML
{
   my $self = shift;

   $errstr = undef;

   if (!$XML::Xerces::VERSION)
   {
      #print "loading XML::Xerces...<br>\n";
      local $^W = 0;
      no warnings;
      # Just in case some version of Carp is in effect
      local $SIG{__WARN__} = 'default';
      local $SIG{__DIE__} = 'default';
      eval('require XML::Xerces;' .
           'require XML::Xerces::DOMParse if ($XML::Xerces::VERSION lt "2");');

      if ($@)
      {
         $errstr = "Failed to load XML::Xerces for the validation test";
         return undef;
      }
      
      &XML::Xerces::XMLPlatformUtils::Initialize();
   }
   
   if ($XML::Xerces::VERSION lt "2")
   {
      my $valflag = $XML::Xerces::DOMParser::Val_Auto;
      
      my $parser = XML::Xerces::DOMParser->new();
      $parser->setValidationScheme($valflag);
      $parser->setDoNamespaces(1);
      $parser->setCreateEntityReferenceNodes(1);
      $parser->setDoSchema(1);
      
      my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
      $parser->setErrorHandler($ERROR_HANDLER);
      eval {
         # HACK: I don't understand this, but XML::Xerces doesn't like
         # this variable unless it's been detainted through a regex.
         $self->{filename} =~ /(.+)/ || die "No file specified";
         my $filename = $1;
         
         $parser->parse(XML::Xerces::LocalFileInputSource->new($filename));
      };
   }
   else
   {
      no warnings;
      my $valflag = $XML::Xerces::AbstractParser::Val_Auto;
      
      my $parser = XML::Xerces::XercesDOMParser->new();
      $parser->setValidationScheme($valflag);
      $parser->setDoNamespaces(1);
      $parser->setCreateEntityReferenceNodes(1);
      $parser->setDoSchema(1);
      
      my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
      $parser->setErrorHandler($ERROR_HANDLER);

      my $filename = $self->{filename};
      require File::Spec;
      unless (File::Spec->file_name_is_absolute($filename))
      {
         $filename = File::Spec->rel2abs($filename);
      }
      # Xerces can't handle symlinks.  Sigh...
      if ($filename =~ /^\//) # Unix only
      {
         my $hasSymLinks;
         do
         {
            $hasSymLinks = 0;
            my @parts = split(/\//, $filename);
            shift @parts if (!$parts[0]);
            for (my $i=0; $i<@parts; $i++)
            {
               my $path = "/" . join("/", @parts[0..$i]);
               if (-l $path)
               {
                  my $link = readlink($path);
                  if ($link =~ /\//)
                  {
                     $filename = $link;
                  }
                  else
                  {
                     $filename = File::Spec->rel2abs($link, "/".join("/", @parts[0..$i-1]));
                  }
                  if ($#parts > $i)
                  {
                     $filename .= "/" . join("/", @parts[$i+1..$#parts]);
                  }
                  next;
               }
            }
         }
         while ($hasSymLinks);
      }
      #print "Filename: $filename<br>\n";
      eval {
         $parser->parse(XML::Xerces::LocalFileInputSource->new($filename));
         #$parser->parse($filename);
      };
   }

   if ($@) {
      if (ref $@) {
         $errstr = $@->getMessage();
      } else {
         $errstr = $@;
      }

      # Remove "at <file>.pm line <num>" message
      $errstr =~ s/\s*$//s;
      $errstr =~ s/\s*at [\/\\]\S+ line \d+$//s;

      #&XML::Xerces::XMLPlatformUtils::Terminate();      
      return undef;
   }

   #&XML::Xerces::XMLPlatformUtils::Terminate();
   return 1;
}
#------------------

=item tableName

Returns the name of the SQL table, as specified in the XML file.  If
the XML file does not specify a table name, this returns the empty
string.

=cut

sub tableName
{
   my $self = shift;
   return $self->{tableName};
}
#------------------

=item keyName

Returns the name of the primary key SQL table, as specified in the XML
file.  If the XML file does not specify a key name, this returns the
empty string.

=cut

sub keyName
{
   my $self = shift;
   return $self->{keyName};
}
#------------------

=item query QUERYNAME [VAR => VALUE, ...]

Run a SELECT style query called <queryname>, substituting the
parameter list into the SQL template.  Returns an executed DBI
statement handle object, or undef on failure.

if <queryname> is undefined or the empty string, the default query
will be used.  The default is either a query with no name, if one
exists, or the first query in the query definition file.  If a
nonexistent query is requested, undef is returned.

=cut

sub query
{
   my $self = shift;
   my $queryname = shift;

   my ($sqls, $binds) = $self->_prepare_params($queryname, @_);
   return undef if ((!$sqls) || @$sqls == 0);
   $self->{laststatement} = $sqls->[0];
   $self->{laststatements} = $sqls;
   $self->{lastbinds} = $binds->[0];
   $self->{lastbindss} = $binds;
   my @sths = ();
   my @results = ();
   foreach my $iSQL (0 .. $#$sqls)
   {
      $self->_startclock() if ($global_benchmarking);

      my $sth = $self->getDBH()->prepare($sqls->[$iSQL]) or return wantarray ? () : undef;
      $sth->execute(@{$binds->[$iSQL]}) or return wantarray ? () : undef;

      $self->_stopclock() if ($global_benchmarking);
      $self->_incrStats($queryname) if ($global_benchmarking);

      my $result = $sth->rows();
      $result = "0E0" if (defined $result && $result eq "0");
      push @sths, $sth;
      push @results, $result;
   }
   if (wantarray)
   {
      return map {($sths[$_],$results[$_])} 0 .. $#sths;
   }
   else
   {
      return $sths[0];
   }
}
#------------------

=item do QUERYNAME [VAR => VALUE, ...]

Run a INSERT/UPDATE/DELETE style query, substituting the parameter
list into the SQL template.  Returns a scalar indicating the result of
the statement (false for failure, number of rows affected on success).

QUERYNAME behaves as described in query().

=cut

sub do
{
   my $self = shift;

   my @params = $self->query(@_);
   return $self->_computeResult(@params);
}
sub _computeResult
{
   my $self = shift;
   my @params = @_;

   my $result = 0;
   for (my $i=0; $i < @params; $i+=2)
   {
      my $thisresult = $params[$i+1];
      if ($thisresult)
      {
         $result += $thisresult;
      }
      else
      {
         return undef;
      }
   }
   return $result || "0E0";
}
#------------------

=item getLastInsertID

After an insert statement into a table with an autoincremented primary
key, this command returns the ID number that was auto-generated for
the new row.

Warning: This is specific to MySQL.  I do not believe this function
will work on other database platforms.

=cut

sub getLastInsertID
{
   my $self = shift;

   my $sth = $self->getDBH()->prepare("select LAST_INSERT_ID()") or return undef;
   $sth->execute() or return undef;
   $self->_incrStats() if ($global_benchmarking);
   my ($id) = $sth->fetchrow_array();
   $sth->finish();
   return $id;
}
#------------------

=item storeObject QUERYNAME, OBJECT

Save an object to backend storage, using the specified query.  The
object methods indicated in <bind> accessors will be called to fill in
the SQL statement.

QUERYNAME behaves as described in query().

=cut

sub storeObject
{
   my $self = shift;
   my $queryname = shift;
   my $object = shift;

   my $result = $self->do($queryname, $object, @_);
   $self->_set_obj_result($object, $queryname, 0, $result);
   return $result;
}
#------------------

=item fillObject QUERYNAME, OBJECT

Run the specified query and fill in the object with the returned
fields.  The object should already exist and should have enough fields
filled in to make the query return a unique object.  If any command in
the query returns zero or more than one rows, this request will fail.

QUERYNAME behaves as described in query().

=cut

sub fillObject
{
   my $self = shift;
   my $queryname = shift;
   my $obj = shift;

   my @params = $self->query($queryname, $obj, @_);
   return undef if (@params == 0 || (!$params[0]));

   my $query = $self->_get_query($queryname);
   my @sqlstructs = _gettag($query, "sql");

   for (my $i=0; $i < @params; $i+=2)
   {
      my $sth = $params[$i];
      return undef if (!$sth);
      my $result = $params[$i+1];
      my $sqlstruct = $sqlstructs[$i/2];

      if ($sth->rows() == 0)
      {
         $errstr = "Did not find any matches";
         return undef;
      }
      elsif ($sth->rows() > 1)
      {
         $errstr = "Found too many matches";
         return undef;
      }

      my @fields = _gettag($sqlstruct, "retrieve");

      while (my $row = $sth->fetchrow_hashref)
      {
         foreach my $field (@fields)
         {
            # If the requested fields are "*" or "<tablename>.*" load them all
            if ($field->getAttribute("key") =~ /^(\w+\.)?\*/)
            {
               foreach my $dbFieldName (keys %$row)
               {
                  _obj_set($obj, {key => $dbFieldName},
                           $row->{$dbFieldName});
               }
            }
            else
            {
               my $dbFieldName = $field->getAttribute("as");
               if (!$dbFieldName)
               {
                  $dbFieldName = $field->getAttribute("key");
                  $dbFieldName =~ s/^\w+\.//;  # remove table name if present
               }
               _obj_set($obj, $field->{attributes}, 
                        $row->{$dbFieldName});
            }
         }
         $self->_set_obj_result($obj, $queryname, $i/2, $result);
      }
   }
   return $self->_computeResult(@params);
}
#------------------

=item retrieveObjects QUERYNAME, PACKAGE, NEW_ARGS [ARGUMENTS]

Run the specified query and return an array of objects of class
PACKAGE.  The objects will be created by calling PACKAGE->new().  Any
extra arguments to this function will be passed as arguments to new().
The objects will be filled with the values from the rows returned by
the query.

NEW_ARGS is an array reference of arguments passed to the 'new'
function of PACKAGE.

QUERYNAME behaves as described in query().

=cut

sub retrieveObjects
{
   my $self = shift;
   my $queryname = shift;
   my $pkg = shift;
   my $newargs = shift;

   my @params = $self->query($queryname, @_);
   return () if (@params == 0 || (!$params[0]));

   my $query = $self->_get_query($queryname);
   my @sqlstructs = _gettag($query, "sql");

   my @list = ();
   for (my $i=0; $i < @params; $i+=2)
   {
      my $sth = $params[$i];
      my $result = $params[$i+1];
      my $sqlstruct = $sqlstructs[$i/2];

      # If not a SELECT, or if the SELECT has no records, skip this $sth
      if (!$sth->FETCH('NAME') || $sth->rows <= 0)
      {
         next;
      }

      my @fields = _gettag($sqlstruct, "retrieve");

      while (my $row = $sth->fetchrow_hashref)
      {
         my $obj = $pkg->new(@$newargs);
         foreach my $field (@fields)
         {
            # If the requested fields are "*" or "<tablename>.*" load them all
            if ($field->getAttribute("key") =~ /^(\w+\.)?\*/)
            {
               foreach my $dbFieldName (keys %$row)
               {
                  _obj_set($obj, {key => $dbFieldName},
                           $row->{$dbFieldName});
               }
            }
            else
            {
               my $dbFieldName = $field->getAttribute("as");
               if (!$dbFieldName)
               {
                  $dbFieldName = $field->getAttribute("key");
                  $dbFieldName =~ s/^\w+\.//;  # remove table name if present
               }
               _obj_set($obj, $field->{attributes}, 
                        $row->{$dbFieldName});
            }
         }
         push @list, $obj;
         $self->_set_obj_result($obj, $queryname, $i/2, $result);
      }
   }
   return @list;
}

#------------------
# PRIVATE function:
# Tell an object the result of the SQL query, if applicable

sub _set_obj_result
{
   my $self = shift;
   my $object = shift;
   my $queryname = shift;
   my $i = shift || 0;
   my $result = shift;

   my $query = $self->_get_query($queryname);
   return undef if (!$query);
   my $sqlstruct = (_gettag($query, "sql"))[$i];
   my $rescmd = (_gettag($sqlstruct, "result"))[0];
   if ($rescmd)
   {
      return _obj_set($object, $rescmd->{attributes}, $result);
   }
   return 1;
}

#------------------
# PRIVATE function:
# Given a CAM::XML object, or its child arrayref, 
# return the all tags of a given type

sub _gettag
{
   my $obj = shift;
   my $tag = shift;

   $obj = $obj->{children} if (ref($obj) ne "ARRAY" && $obj->isa("CAM::XML"));
   return grep {$_->{name} && $_->{name} eq $tag} @$obj;
}

#------------------
# PRIVATE function:
# Find a query with the given name

sub _get_query
{
   my $self = shift;
   my $queryname = shift;

   my $query;
   if ((!defined $queryname) || $queryname eq "")
   {
      $queryname = "_default";
      $query = $self->{defaultquery};
   }
   else
   {
      $query = $self->{queries}->{$queryname};
   }

   if (!$query)
   {
      return undef;
   }
   return $query;
}

#------------------
# PRIVATE function:
# Replace parameter place holders in the SQL template.  Bind values
# are returned for later use in execution.

sub _prepare_params
{
   my $self = shift;
   my $queryname = shift;

   my $query = $self->_get_query($queryname);
   if (!$query)
   {
      &carp("There is no such query named '$queryname' in $$self{filename}");
      return ();
   }

   my $binds = [];
   my $sqls = [];

   # TODO: check for unset params?  Or just leave them undef?
   my $obj;
   if ($_[0] && ref($_[0]))
   {
      $obj = shift;
   }
   my %params = (@_);

   my @sqlstructs = _gettag($query, "sql");
   foreach my $sqlstruct (@sqlstructs)
   {
      my $bind = [];
      my $sql = "";
      foreach my $part ($sqlstruct->getChildren())
      {
         if ($part->isa("CAM::XML::Text"))
         {
            $sql .= $part->{text};
         }
         else
         {
            # Policy: if we have an object, prefer the passed
            # parameter over the object, ALWAYS

            my $type = $part->{name};
            if ($type eq "retrieve")
            {
               $sql .= $part->getAttribute("key");
               if ($part->getAttribute("as"))
               {
                  $sql .= " as " . $part->getAttribute("as");
               }
            }
            elsif ($type eq "replace")
            {
               my $val;
               if ($obj && (!exists $params{$part->getAttribute("key")}))
               {
                  $val = &_obj_get($obj, $part->{attributes});
               }
               else
               {
                  $val= $params{$part->getAttribute("key")};
               }
               $sql .= defined $val ? $val : "";
            }
            else
            {
               if ($obj && (!exists $params{$part->getAttribute("key")}))
               {
                  push @$bind, &_obj_get($obj, $part->{attributes});
               }
               else
               {
                  my $key = $part->getAttribute("key");
                  my $default = $part->getAttribute("default");
                  my $val = defined $params{$key} ? $params{$key} : $default;
                  push @$bind, $val;
               }
               $sql .= "?";
            }
         }
      }
      push @$sqls, $sql;
      push @$binds, $bind;
   }

   return ($sqls, $binds);
}

#------------------
# PRIVATE function:
# call the accessor of an object, return the result
# if the accessor fails, try to retrieve the field directly

sub _obj_get
{
   my $object = shift;
   my $s = shift;

   my $result;
   no strict 'refs';
   if ($global_safe_functions)
   {
      if ($s->{accessor})
      {
         my $function = $s->{accessor};
         $result = eval {$object->$function()};
         if ($@)
         {
            my $function = "get".$s->{key};
            $result = eval {$object->$function()};
            if ($@)
            {
               $result = $object->{$s->{key}};
            }
         }
      }
      else
      {
         my $function = "get".$s->{key};
         $result = eval {$object->$function()};
         if ($@)
         {
            $result = $object->{$s->{key}};
         }
      }
   }
   else
   {
      if ($s->{accessor})
      {
         my $function = $s->{accessor};
         $result = $object->$function();
      }
      else
      {
         my $function = "get".$s->{key};
         $result = $object->$function();
      }
   }
   if (!defined $result)
   {
      $result = $s->{default};
   }
   return $result;
}

#------------------
# PRIVATE function:
# call the mutator of an object with the specified value, return the result
# if the mutator fails, try to set the field directly

sub _obj_set
{
   my $object = shift;
   my $s = shift;
   my $value = shift;
   
   if (!$s->{key})
   {
      warn "this object has no key";
      return 0;
   }
   no strict 'refs';
   if ($global_safe_functions)
   {
      if ($s->{mutator})
      {
         my $function = $s->{mutator};
         my $result = eval {$object->$function($value)};
         return 1 if (!$@);
      }
      if ($s->{as})
      {
         my $function = "set".$s->{as};
         my $result = eval {$object->$function($value)};
         return 1 if (!$@);
      }
      my $function = "set".$s->{key};
      my $result = eval {$object->$function($value)};
      return 1 if (!$@);
      
      $object->{$s->{key}} = $value;
   }
   else
   {
      if ($s->{mutator})
      {
         my $function = $s->{mutator};
         $object->$function($value);
      }
      elsif ($s->{as})
      {
         my $function = "set".$s->{as};
         $object->$function($value);
      }
      else
      {
         my $function = "set".$s->{key};
         $object->$function($value);
      }
   }
   return 1;
}

#------------------
# PRIVATE function:
#   update the stats data structure for this query

sub _incrStats
{
   my $self = shift;
   my $queryname = shift;

   $global_stats{queries}++;
   my $cmdData = $global_stats{cmds}->{$self->{cmd}};
   $cmdData->{queries}++;
   if ($queryname)
   {
      my $queryData = $cmdData->{query}->{$queryname};
      $queryData->{queries}++;
      if ($self->{_time})
      {
         $global_stats{time} += $self->{_time};
         $cmdData->{time} += $self->{_time};
         $queryData->{time} += $self->{_time};
      }
   }
}

#------------------
# PRIVATE functions:
#   measure elapsed time

sub _startclock
{
   my $self = shift;

   delete $self->{_time};
   
   $self->{_clock} = [Time::HiRes::gettimeofday()];
}
sub _stopclock
{
   my $self = shift;

   if (defined $self->{_clock})
   {
      $self->{_time} = Time::HiRes::tv_interval($self->{_clock});
      delete $self->{_clock};
   }
}
#------------------

=item statistics

Return a data structure of statistics for this package.  The data
structure looks like this:

    $stats = {
       queries => <number>,
       time => <seconds>,
       cmds => {
          "sqlone.xml" => {
             queries => <number>,
             time => <seconds>,
             query => {
                "queryone" => {
                   queries => <number>,
                   time => <seconds>,
                },
                "querytwo" => {
                   queries => <number>,
                   time => <seconds>,
                },
             }
          },
          "sqltwo.xml" => {
             queries => <number>,
             time => <seconds>,
             query => {
                "queryone" => {
                   queries => <number>,
                   time => <seconds>,
                },
             }
          },
       },
    };

The returned structure is a reference to live data so DO NOT alter it
in any way!  Treat it as read-only data.

=cut

sub statistics
{
   my $pkg = shift;

   if ($global_benchmarking)
   {
      return \%global_stats;
   }
   else
   {
      return undef;
   }
}
#------------------

=item statisticsHTML

This class method returns an HTML string that renders the statistics
data in a human readable format.

=cut

sub statisticsHTML
{
   my $pkg = shift;

   my $stats = $pkg->statistics();
   return "" if (!$stats);
   my $html = "<pre>";
   $html .= "queries ".$stats->{queries}."\n";
   $html .= "time    ".$stats->{time}."\n";
   foreach my $cmd (sort keys %{$stats->{cmds}})
   {
      my $cmdData = $stats->{cmds}->{$cmd};
      $html .= "   $cmd\n";
      $html .= "      queries ".$cmdData->{queries}."\n";
      $html .= "      time    ".$cmdData->{time}."\n";
      foreach my $queryname (sort keys %{$cmdData->{query}})
      {
         my $queryData = $cmdData->{query}->{$queryname};
         next if ($queryData->{queries} == 0);
         $html .= "         $queryname\n";
         $html .= "            queries ".$queryData->{queries}."\n";
         $html .= "            time    ".$queryData->{time}."\n";
      }
   }
   $html .= "</pre>\n";
   return $html;
}
sub _statsKeySort
{
   my %order = (
                queries => 1,
                time => 2,
                cmds => 3,
                query => 4,
                other => 5,
                );
   ($order{$a} || $order{other}) <=> ($order{$a} || $order{other}) || $a cmp $b;
}
#------------------

=item toForm QUERYNAME

Return the body of an HTML form useful for testing and evaluting the
SQL template.  Use it something like this:

    my $sql = CAM::SQLManager->new("somecommand");
    print "<form action="$URL">";
    print $sql->toForm();
    print "<input type=submit>";
    print "</form>";

=cut

sub toForm
{
   my $self = shift;
   my $queryname = shift;

   my $form = "";
   my $query = $self->_get_query($queryname);
   return undef if (!$query);
   my @sqlstructs = _gettag($query, "sql");
   foreach my $i (0 .. $#sqlstructs)
   {
      my $sqlstruct = $sqlstructs[$i];
      foreach my $part ($sqlstruct->getChildren())
      {
         if ($part->isa("CAM::XML::Text"))
         {
            $form .= &_html_escape($part->{text});
         }
         else
         {
            my $type = $part->{name};
            if ($type eq "retrieve")
            {
               $form .= &_html_escape($part->getAttribute("key"));
               if ($part->getAttribute("as"))
               {
                  $form .= &_html_escape(" as " . $part->getAttribute("as"));
               }
               #$form .= &_html_escape("<% ".$part->getAttribute("key").":".$part->getAttribute("mutator")." %>");
            }
            else
            {
               $form .= "<input name=\"".$part->getAttribute("key")."\"> (".$part->getAttribute("key").")";
            }
         }
      }
   }
      
   $form .= "<br>Optionally, limit output to rows between <input type=text name=sqlform_startrow> and <input type=text name=sqlform_endrow><br>\n";

   return $form;
}
#------------------

=item fromForm [CGI object]

Accept input from an HTML form like the one output by toForm() and
return HTML formatted output.

=cut

sub fromForm
{
   my $self = shift;
   my $queryname = shift;
   my $cgi = shift;

   my $html = "";

   my $start = $cgi->param('sqlform_startrow');
   my $end   = $cgi->param('sqlform_endrow');

   my %params = ();
   foreach my $key ($cgi->param)
   {
      $params{$key} = $cgi->param($key);
   }
   my @results = $self->query($queryname, %params);
   my @explains = ();
   for (my $i = 0; $i < @results; $i+=2)
   {
      my $sth = $results[$i];
      if (!$sth)
      {
         $html .= "Query failed: ";
      }
      else
      {
         my $sql = $sth->{Statement};
         my $sqlst = &_html_escape($sql);
         if ($self->{lastbindss}->[$i/2])
         {
            my @binds = @{$self->{lastbindss}->[$i/2]};
            my $i=0;
            $sql =~ s/\?/$self->getDBH()->quote($binds[$i++])/ge;
            $i=0;
            $sqlst =~ s/\?/"<strong>".$self->getDBH()->quote($binds[$i++])."<\/strong>"/ge;
         }
         push @explains, "explain $sql" if ($sql =~ /^\s*select\s/si);
         $html .= "Final query (reconstructed): <blockquote>$sqlst</blockquote><br>\n";
         my $rows = $sth->rows();
         $rows = undef if (defined $rows && $rows eq "");
         $rows = "(undefined)" if (!defined $rows);
         $html .= "Rows: $rows<br>\n";
         my $row = 0;
         if ($sth->FETCH('NAME'))
         {
            $html .= "<table border=1>\n";
            $html .= "<tr><th>" . join("</th><th>", "Row", @{$sth->FETCH('NAME')}) . "</th></tr>\n";
            while (my $ref = $sth->fetchrow_arrayref)
            {
               $row++;
               next if ($start && $row < $start);
               last if ($end && $row > $end);
               my @data = map {&_html_escape($_)} @$ref;
               @data = map {$_ eq "" ? "&nbsp;" : $_} @data;
               $html .= "<tr><td>" . join("</td><td>", $row, @data) . "</td></tr>\n";
            }
            $html .= "</table>\n";
         }
      }
   }

   $html .= "<br>Explain queries:<br>\n";
   foreach my $explain (@explains)
   {
      my $sth = $self->getDBH()->prepare($explain);
      $sth->execute();
      $html .= "<table border=1>\n";
      $html .= "<tr><th>" . join("</th><th>", @{$sth->FETCH('NAME')}) . "</th></tr>\n";
      while (my $ref = $sth->fetchrow_arrayref)
      {
         my @data = map {&_html_escape($_)} @$ref;
         @data = map {$_ eq "" ? "&nbsp;" : $_} @data;
         $html .= "<tr><td>" . join("</td><td>", @data) . "</td></tr>\n";
      }
      $html .= "</table>\n";
   }

   return $html;
}
#------------------

=item testCommands

=item testCommands CGIobject

A nearly complete CGI program to run tests on your library SQL
commands.  You may optionally pass it a CGI object, if you want it to
work as part of a larger framework.  Otherwise, the function
instantiates it's own CGI object.  Here is an complete CGI program
using this function:

  #!/usr/bin/perl
  use CAM::SQLManager;
  use DBI;
  my $dbh = DBI->connect(blah blah);
  CAM::SQLManager->setDBH($dbh);
  CAM::SQLManager->setDirectory("/path/to/sql/library");
  CAM::SQLManager->setBenchmarking(1);  # optional
  CAM::SQLManager->testCommands();


=cut

sub testCommands
{
   my $pkg = shift;
   my $cgi = shift;

   if (!$global_dbh)
   {
      die "You must call CAM::SQLManager::setDBH first";
   }
   if (!$global_directory)
   {
      die "You must call CAM::SQLManager::setDirectory first";
   }

   if (!$cgi)
   {
      require CGI;
      $cgi = CGI->new;
      print $cgi->header();
   }
   my $url = $cgi->url();
   my $novalidate = $cgi->param("novalidate");
   my $validatearg = $novalidate ? "&novalidate=1" : "";
   my $cmd = $cgi->param('cmd');
   $cgi->delete('novalidate');
   $cgi->delete('cmd');

   if (!$cmd)
   {
      print qq[<a href="$url?cmd=_testall">Test all XML files</a><br>\n];
      print qq[<br>\n];

      foreach my $file ($pkg->getAllCmds())
      {
         my $name = $file;
         $name =~ s,^$global_directory[/\\]?,,;

         print qq[<a href="$url?cmd=$name$validatearg">$name</a><br>\n];
      }
   }
   elsif ($cmd eq "_testall")
   {
      foreach my $file ($pkg->getAllCmds())
      {
         $file =~ s,^$global_directory[/\\]?,,;
         print "$file: ";
         my $sql = CAM::SQLManager->new($file);
         if ($sql)
         {
            if ($sql->validateXML())
            {
               print "OK<br>\n";
            }
            elsif (!$XML::Xerces::VERSION)
            {
               print "This command was not validated (XML::Xerces is not installed)<br>\n";
            }
            else
            {
               print "This command did not pass the validation test:<br>$errstr<br>\n";
            }
         }
         else
         {
            print "Failed to create new sql object<br>\n";
         }
      }
   }
   else
   {
      my $sql = CAM::SQLManager->new($cmd);
      die "Failed to create new sql object" if (!$sql);

      if ($novalidate)
      {
         print "Validation tests disabled<p>\n";
      }
      else
      {
         if (!$sql->validateXML())
         {
            if (!$XML::Xerces::VERSION)
            {
               print "This command was not validated (XML::Xerces is not installed)<p>\n";
            }
            else
            {
               print "This command did not pass the validation test:<br>$errstr<p>\n";
            }
         }
      }

      my $queryname = $cgi->param('queryname');
      $cgi->delete('queryname');
      if (!defined $queryname)
      {
         if (keys(%{$sql->{queries}}) == 1)
         {
            ($queryname) = keys(%{$sql->{queries}});
         }
         else
         {
            print "Select a query to test for $cmd:<br>\n";
            foreach my $name (sort keys %{$sql->{queries}})
            {
               print qq[<a href="$url?cmd=$cmd&queryname=$name$validatearg">$name</a><br>\n];
            }
            print "<br><br>Original document: <blockquote>" . &_html_escape($sql->{sql}) . "</blockquote><br>\n";
            return;
         }
      }

      my @parms = $cgi->param();
      if (@parms == 0)
      {
         print "<form action=\"$url\">\n";
         if ($novalidate)
         {
            print "<input type=hidden name=novalidate value=1>\n";
         }
         print "<input type=hidden name=cmd value=\"$cmd\">\n";
         print "<input type=hidden name=queryname value=\"$queryname\">\n";
         print $sql->toForm($queryname);
         print "<input type=submit>\n";
         print "</form>\n";
      }
      else
      {
         print $sql->fromForm($queryname, $cgi);
         print "<hr>Statistics:\n";
         print $pkg->statisticsHTML();
      }
   }
}

#------------------
# PRIVATE function:
# Convert a block of text so it displays nicely in HTML

sub _html_escape
{
   my $text = shift;

   $text = "NULL" if (!defined $text);
   $text =~ s/&/&amp;/g;
   $text =~ s/"/&quot;/g;
   $text =~ s/</&lt;/g;
   $text =~ s/>/&gt;/g;
   $text =~ s/\r?\n/<br>\n/g;
   $text =~ s/\r/<br>\n/g;
   $text =~ s/^ /&nbsp;/gm;
   $text =~ s/  /&nbsp; /g;

   return $text;
}

1;
#------------------
__END__

=back

=head1 XML STRUCTURE

The SQL commands should be encapsulated in one or more XML documents.
The structure of this XML is specified in CAM-SQL.dtd.  Here is an
example XML SQL query:

=cut

# Note: the following XML is used in the test script!
## START TEST XML

=pod

  <?xml version="1.0" encoding="UTF-8" standalone="no" ?>
  <!DOCTYPE sqlxml SYSTEM "CAM-SQL.dtd">
  <sqlxml>
    <table name="user" primarykey="username"/>
    <query name="GetUser">
     <sql>
        select
          <retrieve key="firstName" mutator="setNickName"/>
          <retrieve key="lastName" mutator="setLastName"/>
          <retrieve key="date_add(birthdate, interval 65 year)" as="bday65"
                    mutator="setSixtyFifthBirthday"/>
        from user
        where 
          username = <bind key="username" accessor="getUserName"/>
        and
          password = <bind key="password" accessor="promptForPassword"/>
      </sql>
    </query>
    <query name="DeleteUser">
      <result key="result" mutator="setDeleteResult"/>
      <sql>
        delete from user
        where 
          username = <bind key="username" accessor="getUserName"/>
      </sql>
    </query>
    <query name="AddUser">
      <sql>
        insert into user
        set 
          username  = <bind key="username" accessor="getUserName"/>,
          password  = <bind key="password" accessor="getPassword"/>,
          firstName = <bind key="firstName" accessor="getNickName"/>,
          lastName  = <bind key="lastName" accessor="getLastName"/>,
          birthdate = <bind key="birthdate" accessor="getBirthDate"/>,
          city      = <bind key="city" accessor="getCity" default="Madison"/>,
          state     = <bind key="state" accessor="getState" default="WI"/>,
          zip       = <bind key="zip" accessor="getZipCode" default="53711"/>
      </sql>
    </query>
    <query name="GetUserAddresses">
     <sql>
        select
          <retrieve key="city" mutator="setCity"/>
          <retrieve key="state" mutator="setState"/>
          <retrieve key="zip" mutator="setZipCode"/>
        from user
        order by
          <replace key="orderby"/>
      </sql>
    </query>
  </sqlxml>

=cut

## END TEST XML

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=head1 SEE ALSO

CAM::SQLObject
