package Database::Wrapper;

use strict;
use warnings;
use base qw(Exporter);

our $VERSION = "1.04";
#	$Id: Wrapper.pm,v 1.13 2005/11/26 00:37:34 incorpoc Exp $

use DBI;
use lib qw(..);

# Documentation and examples are at the end of this file after '__END__'

our $ConnectionError = undef; # Only used for connection errors
our $WarnDifferentPrepare = 0;

use constant RETURNTYPE_NONE									=> 0;
use constant RETURNTYPE_SUCCESS								=> 1;
use constant RETURNTYPE_VALUE									=> 2; # The value of the first field of the first record
use constant RETURNTYPE_ALLVALUES						  => 7; # Array of all the first field of all records
use constant RETURNTYPE_HASHREF								=> 3; # The first record as a hash ref
use constant RETURNTYPE_ARRAYREF							=> 4; # The first record as an array ref
use constant RETURNTYPE_ARRAYREFOFHASHREFS		=> 5; # All records as hash refs
use constant RETURNTYPE_ARRAYREFOFARRAYREFS		=> 6; # All records as array refs

use constant CONNECTION_TYPE_MySQL						=> 1;
use constant CONNECTION_TYPE_ODBC							=> 2;
use constant CONNECTION_TYPE_Postgres					=> 3;
use constant CONNECTION_TYPE_SQLite           => 4;

my @aReturnTypes = qw(RETURNTYPE_NONE RETURNTYPE_SUCCESS RETURNTYPE_VALUE RETURNTYPE_ALLVALUES RETURNTYPE_HASHREF RETURNTYPE_ARRAYREF RETURNTYPE_ARRAYREFOFHASHREFS RETURNTYPE_ARRAYREFOFARRAYREFS);
my @aConnectionTypes = qw(CONNECTION_TYPE_MySQL CONNECTION_TYPE_ODBC CONNECTION_TYPE_Postgres  CONNECTION_TYPE_SQLite);
our @EXPORT_OK = (@aReturnTypes, @aConnectionTypes);
our %EXPORT_TAGS = (RETURN_TYPES => \@aReturnTypes, CONNECTION_TYPES => \@aConnectionTypes);

my $rhDriverNames =
	{
	CONNECTION_TYPE_MySQL()     => "mysql",
	CONNECTION_TYPE_ODBC()	    => "ODBC",
	CONNECTION_TYPE_Postgres()	=> "Pg",
  CONNECTION_TYPE_SQLite()    => "SQLite2",
	};

sub new($$)
	{
	my ($class, $rhConnection) = (shift, shift);
	
	$ConnectionError = "";
  if(not defined $rhConnection)
    {
    $ConnectionError = "Database::Wrapper::new(), '$rhConnection' parameter undefined";
    return undef;
    }
  if(ref($rhConnection) ne "HASH")
    {
    $ConnectionError = "Database::Wrapper::new(), '$rhConnection' must be hash reference";
    return undef;
    }
  
	my $nConnectionType = $rhConnection->{ConnectionType};
	my $sDatabaseName = $rhConnection->{DatabaseName};
	my $sUser = $rhConnection->{User};
	my $sPassword = $rhConnection->{Password};
	my $sHost = $rhConnection->{Host};
	my $rhAttribs = (exists $rhConnection->{Attribs})? $rhConnection->{Attribs} : {};
	$rhAttribs->{RaiseError} = defined($rhAttribs->{RaiseError})? $rhAttribs->{RaiseError} : 1;
	$rhAttribs->{PrintError} = defined($rhAttribs->{PrintError})? $rhAttribs->{PrintError} : 0;
	$rhAttribs->{AutoCommit} = defined($rhAttribs->{AutoCommit})? $rhAttribs->{AutoCommit} : 1;
  
	my $sDbiConnectionString = _MakeDsn($nConnectionType, $sDatabaseName, $sHost);
  if(not defined $sDbiConnectionString)
    {
    # No need to set '$ConnectionError', it is set by _MakeDsn()
    return undef;
    }

  my $rhConnectionData =
    {
    ConnectionType      => $nConnectionType,
    DatabaseName        => $sDatabaseName,
    User                => $sUser,
    Password            => $sPassword,
    Host                => $sHost,
    Attribs             => $rhAttribs,
		DbiConnectionString	=> $sDbiConnectionString,
    };
  my $dbh = _Connect($rhConnectionData);
  return undef
  	if(not defined $dbh);

  my $self =
		{
		%$rhConnectionData,
    dbh                 => $dbh,
		Queries							=> {},
		LastError						=> "",
		};
	SWITCH:
		{
		if($nConnectionType == CONNECTION_TYPE_MySQL)
			{
      require Database::Wrapper::MySQL;
			return Database::Wrapper::MySQL->_Create($self);
			}
		if($nConnectionType == CONNECTION_TYPE_ODBC)
			{
      require Database::Wrapper::ODBC;
			return Database::Wrapper::ODBC->_Create($self);
			}
		if($nConnectionType == CONNECTION_TYPE_Postgres)
			{
      require Database::Wrapper::Postgres;
			return Database::Wrapper::Postgres->_Create($self);
			}
  	if($nConnectionType == CONNECTION_TYPE_SQLite)
			{
      require Database::Wrapper::SQLite;
			return Database::Wrapper::SQLite->_Create($self);
			}
		$ConnectionError = "Database::Wrapper::new(), unknown 'ConnectionType' given: '$nConnectionType'";
		return undef;
		}
	}

# Utility function for db connection
# Side effects: sets '$ConnectionError'
sub _Connect($)
  {
  my ($rhConnectionData)  = (shift);

	my $dbh = undef;
  eval
		{
		$dbh = DBI->connect($rhConnectionData->{DbiConnectionString}, $rhConnectionData->{User}, $rhConnectionData->{Password}, $rhConnectionData->{Attribs});
		};
	if($@)
		{
    if(defined $DBI::errstr)
      {
      my $sDBIError = DBI->errstr;
      $ConnectionError = "DBI->connect() failed with error '$sDBIError'.";
      return undef;
      }
    else
      {
      $ConnectionError = "DBI->connect() failed with error '$@'.";
      return undef;
      }
		}
	if(not defined $dbh)
		{
    # Is this case possible?
		my $sUndefError = DBI->errstr;
		$ConnectionError = "DBI->connect() returned undef with error '$sUndefError'.";
		return undef;
		}
  
  return $dbh;
  }

sub GetLastError($)
	{
	my ($self) = (shift);

	return $self->{LastError};
	}

sub DESTROY($)
	{
	my ($self) = (shift);

	return
		if(not exists $self->{dbh});
	return
		if(not defined $self->{dbh});
	$self->{dbh}->disconnect();
	$self->{dbh} = undef;
  delete $self->{dbh};
	}

sub commit($)
	{
	my ($self) = (shift);

	my $dbh = $self->{dbh};
	return
		if(not defined $dbh);
  eval
    {
  	$dbh->commit();
    };
	}

sub GetDriverName($)
	{
	my ($nConnectionType) = (shift);

	return undef
		if(not exists $rhDriverNames->{$nConnectionType});

	return $rhDriverNames->{$nConnectionType};
	}

# A standard function for all the data definition query functions

# Receives a reference to the calling sub's '@_'
sub _GetConnectionData
  {
  my $raArgs = shift;
  if(scalar @$raArgs == 0)
    {
    warn("No parameters supplied");
    return undef;
    }
  my $par = shift @$raArgs;
  if(not defined $par)
    {
    warn("First parameter undef");
    return undef;
    }

  my $rhConnectionData = {};
  SWITCH:
    {
    if(ref($par) eq "")
      {
      # Check for the deprecated call
      $rhConnectionData->{ConnectionType} = $par;
      my $rhAttribs = shift @$raArgs;
      if(ref($rhAttribs) ne "HASH")
        {
        warn("Hash expected as second parameter");
        return undef;
        }
      $rhConnectionData->{User} = $rhAttribs->{user};
      $rhConnectionData->{Password} = $rhAttribs->{password};
      $rhConnectionData->{Host} = $rhAttribs->{host};
      $rhConnectionData->{Port} = $rhAttribs->{port};
      last;
      }
    if(ref($par) eq "HASH")
      {
      # Static call
      my $rhConnection = $par;
      $rhConnectionData->{ConnectionType} = $rhConnection->{ConnectionType};
      $rhConnectionData->{User} = $rhConnection->{User};
      $rhConnectionData->{Password} = $rhConnection->{Password};
      $rhConnectionData->{Host} = $rhConnection->{Host};
      $rhConnectionData->{Port} = $rhConnection->{Port};
      last;
      }
    if(UNIVERSAL::isa($par, "Database::Wrapper"))
      {
      my $dbw = $par;
      $rhConnectionData->{ConnectionType} = $dbw->{ConnectionType};
      $rhConnectionData->{User} = $dbw->{User};
      $rhConnectionData->{Password} = $dbw->{Password};
      $rhConnectionData->{Host} = $dbw->{Host};
      $rhConnectionData->{Port} = $dbw->{Port};
      last;
      }
    warn("Incorrect parameters");
    return undef;
    }
	my $sDriver = GetDriverName($rhConnectionData->{ConnectionType});
	return undef
		if(not defined $sDriver);

  $rhConnectionData->{Driver} = $sDriver;

  return $rhConnectionData;
  }

sub GetDatabaseNames
	{
  my $rhConnectionData = _GetConnectionData(\@_);
  return undef
    if(not defined $rhConnectionData);

	my $rasDatabases = undef;
  SWITCH:
    {
    if($rhConnectionData->{ConnectionType} == CONNECTION_TYPE_MySQL)
      {
      my $rhAttribs =
        {
        user      => $rhConnectionData->{User},
        password  => $rhConnectionData->{Password},
        host      => $rhConnectionData->{Host},
        port      => $rhConnectionData->{Port},
        };
      $rasDatabases = [DBI->data_sources($rhConnectionData->{Driver}, $rhAttribs)];
      # Names are returned in the form 'dbi:DRIVER_NAME:DATABASE_NAME'
      # Strip off 'dbi:DRIVER_NAME:'
      grep{s/.*?\:([^\:]*$)/$1/go} @$rasDatabases;
      if(not defined $rasDatabases)
        {
        warn("data_sources() returned undef");
        return undef;
        }
      last;
      }
    if($rhConnectionData->{ConnectionType} == CONNECTION_TYPE_ODBC)
      {
      $rasDatabases = [DBI->data_sources($rhConnectionData->{Driver})];
      grep{s/.*?\:([^\:]*$)/$1/go} @$rasDatabases;
      if(not defined $rasDatabases)
        {
        warn("data_sources() returned undef");
        return undef;
        }
      last;
      }
    if($rhConnectionData->{ConnectionType} == CONNECTION_TYPE_Postgres)
      {
      # Aargh! Listing databases in Postgres requires a connection to 'template1'.
      # If the connection requires authentication, the module offers no way of passing user and password.
      # It will only look for them in the environment. Seems like a stroke of genius ;-)
      local $ENV{DBI_USER} = $rhConnectionData->{User};
      local $ENV{DBI_PASS} = $rhConnectionData->{Password};
      $rasDatabases = [DBI->data_sources($rhConnectionData->{Driver})];
      if(not defined $rasDatabases)
        {
        warn("data_sources() returned undef");
        return undef;
        }
      grep{s/.*?:dbname=(.*)/$1/go} @$rasDatabases;
      last;
      }
    warn("Unrecognised ConnectionType '$rhConnectionData->{ConnectionType}'");
    return undef;
    }
	return $rasDatabases;
	}

sub DatabaseExists
	{
	my ($parOne, $sName, $parThree) = (shift, shift, shift);

	my $raDatabases = GetDatabaseNames($parOne, $parThree);
	my $bFound = grep {$_ eq $sName} @$raDatabases;

	return $bFound;
	}

sub GetTableNames($)
	{
	my ($self) = (shift);

	my $raTables = [$self->{dbh}->tables];

	return $raTables;
	}

sub TableExists($$)
	{
	my ($self, $sTableToFind) = (shift, shift);
	my $raTables = $self->GetTableNames();
  foreach my $sTable (@$raTables)
    {
    return 1
      if($sTable eq $sTableToFind);
    }

  return 0;
	}

sub GetUserNames
  {
  warn("GetUserNames() has not been implemented for this Database type");
  
  return undef;  
  }

sub PrepareQuery($$$$)
	{
	my ($self, $sName, $sqry, $nReturnType) = (shift, shift, shift, shift);

	$self->{LastError} = "";

	if(not defined $sName || $sName eq "")
		{
		$self->{LastError} = "Query name '$sName' invalid.";
		return 0;
		}

  if($self->QueryExists($sName))
    {
    if($WarnDifferentPrepare)
      {
      my $sthExisiting = $self->{Queries}->{$sName};
      my $sqryPrepared = $sthExisiting->{Statement};
      warn("Attempt to redefine '$sName'. Original query '$sqryPrepared', new definition '$sqry'")
        if($sqryPrepared ne $sqry);
      }
    # Return 'Success', as you can call PrepareQuery() more than once on any given query.
    return 1;
    }

	my $sth = undef;
	eval
		{
		$sth = $self->{dbh}->prepare($sqry);
		};
	if($@)
		{
		$self->{LastError} = "PrepareQuery(): error during prepare('$sqry'): $@";
		return 0;
		}
	if(DBI::err)
		{
		$self->{LastError} = DBI::errstr;
		return 0;
		}
	if(not defined $sth)
		{
		$self->{LastError} = "PrepareQuery(): prepare('$sqry') failed.";
		return 0;
		}
	$self->{Queries}->{$sName} =
		{
		Handle			=> $sth,
		ReturnType	=> $nReturnType || RETURNTYPE_NONE,
		};
	return 1;
	}

sub QueryExists($$)
	{
	my ($self, $sName) = (shift, shift);

	return 0
		if(not defined $sName || $sName eq "");
	return exists $self->{Queries}->{$sName};
	}

sub RunSql
  {
  my ($self, $sql, $reSplit)  = (shift, shift, shift);
  
  my $dbh = $self->{dbh};
  
  $reSplit = (defined $reSplit)? $reSplit : qr(;[\r\n]+);
  
  # Split into statements
  my $raLines = [split($reSplit, $sql)];

  foreach my $sLine (@$raLines)
    {
    # Strip comments
    $sLine =~ s/^--[^\r\n]*[\r\n]//gom;
    # Strip empty lines
    $sLine =~ s/^[\r\n]//gom;
    next
      if($sLine eq "");

    eval
      {
      $dbh->do($sLine);
      };
    if($@)
      {
      if(defined $DBI::errstr)
        {
    		$self->{LastError} = "RunSql(): " . DBI->errstr . ".";
        return undef;
        }
      else
        {
    		$self->{LastError} = "RunSql(): $@.";
        return undef;
        }
      }
    }
  
  return 1;
  }

=pod

Execute a stored query

=cut

sub ExecuteQuery($$$)
	{
	my ($self, $sName, $raParameters) = (shift, shift, shift);

	$self->{LastError} = "";

	$raParameters = $raParameters || [];
	if(not defined $sName)
		{
		$self->{LastError} = "ExecuteQuery(): No query name supplied.";
		return undef;
		}
	if($sName eq "")
		{
		$self->{LastError} = "ExecuteQuery(): Query name supplied was empty string.";
		return undef;
		}
	if(not exists $self->{Queries}->{$sName})
		{
		$self->{LastError} = "ExecuteQuery(): Query '$sName' does not exist.";
		return undef;
		}
	my $qry = $self->{Queries}->{$sName};
	my $sth = $qry->{Handle};
	if(not defined $sth)
		{
		$self->{LastError} = "ExecuteQuery(): Query handle for '$sName' not defined.";
		return undef;
		}
	my $nReturnType = $qry->{ReturnType};
	return $self->_ExecuteQueryOnHandle($sth, $raParameters, $nReturnType);
	}

sub ExecuteTemporaryQuery($$$$)
	{
	my ($self, $sqry, $raParameters, $nReturnType) = (shift, shift, shift, shift);

	$self->{LastError} = "";

	my $sth = undef;
	eval
		{
		$sth = $self->{dbh}->prepare($sqry);
		};
	if(DBI::err)
		{
		$self->{LastError} = DBI::errstr;
		return undef;
		}
	return $self->_ExecuteQueryOnHandle($sth, $raParameters, $nReturnType);
	}

sub GetNewInsertId($$$)
	{
	my ($self, $sTableName, $nIdField) = (shift, shift, shift);

	warn("GetNewInsertId() is deprecated, use GetMaxId()");

	return GetMaxId($self, $sTableName, $nIdField);
	}

=pod

Return:
  MaxId from table or $nDefault if there are no records.

=cut

sub GetMaxId($$$)
	{
	my ($self, $sTableName, $nIdField) = (shift, shift, shift);
  my $nDefault = (scalar @_ > 0)? shift : undef;

	my $sqry = "SELECT MAX($nIdField) AS MaxId FROM $sTableName;";
	my $ra = undef;
	eval
		{
		my $sth = $self->{dbh}->prepare($sqry);
		$sth->execute();
		$ra = $sth->fetchrow_arrayref();
		};
	if($@)
		{
		$self->{LastError} = "GetMaxId(): $@";
		return undef;
		}
	if(DBI::err)
		{
		$self->{LastError} = DBI::errstr;
		return undef;
		}
	return $nDefault
		if(not defined $ra);
  my $nMaxId = $ra->[0];
	return $nDefault
		if(not defined $nMaxId);
	return $nMaxId;
	}

sub _ExecuteQueryOnHandle($$$$)
  {
  my ($self, $sth, $raParameters, $nReturnType) = (shift, shift, shift, shift);

	if(not defined $sth)
		{
		$self->{LastError} = "_ExecuteQueryOnHandle(): No query handle supplied.";
		return undef;
		}
	$raParameters = (defined $raParameters && ref($raParameters) eq "ARRAY")? $raParameters : [];
	$nReturnType = (defined $nReturnType)? $nReturnType : RETURNTYPE_NONE;
	eval
		{
		$sth->execute(@$raParameters);
		};
	if($@)
		{
		$self->{LastError} = "_ExecuteQueryOnHandle(): $@";
		return undef;
		}
	if(DBI::err)
		{
		$self->{LastError} = "_ExecuteQueryOnHandle(): " . DBI::errstr;
		return undef;
		}
	my $ret = undef;
	SWITCH:
		{
		if($nReturnType == RETURNTYPE_NONE)
			{
			last;
			}
		if($nReturnType == RETURNTYPE_SUCCESS)
			{
			$ret = 1;
			last;
			}
		if($nReturnType == RETURNTYPE_VALUE)
			{
			my $ra = $sth->fetchrow_arrayref();
			if(not defined $ra)
				{
				$self->{LastError} = "_ExecuteQueryOnHandle(): fetchrow_arrayref() returned undef";
				last;
				}
			$ret = $ra->[0];
			last;
			}
		if($nReturnType == RETURNTYPE_ALLVALUES)
			{
      $ret = [];
			my $ra = $sth->fetchrow_arrayref();
			while(defined $ra)
				{
        push @$ret, $ra->[0];
        $ra = $sth->fetchrow_arrayref();
				}
			last;
			}
		if($nReturnType == RETURNTYPE_HASHREF)
			{
			my $rh = $sth->fetchrow_hashref();
			if(not defined $rh)
				{
				$self->{LastError} = "_ExecuteQueryOnHandle(): fetchrow_hashref() returned undef";
				last;
				}
			$ret = $rh;
			last;
			}
		if($nReturnType == RETURNTYPE_ARRAYREF)
			{
			my $ra = $sth->fetchrow_arrayref();
			if(not defined $ra)
				{
				$self->{LastError} = "_ExecuteQueryOnHandle(): fetchrow_arrayref() returned undef";
				last;
				}
			# DBI(?) BUG workaround: fetchrow_arrayref hands back the SAME array ref each time,
			# so it stomps on previous values in recursive calls.
			# So, create a new array ref
			$ret = [@$ra];
			last;
			}
		if($nReturnType == RETURNTYPE_ARRAYREFOFARRAYREFS)
			{
			my $ra = $sth->fetchall_arrayref();
			$ret = $ra;
			last;
			}
		if($nReturnType == RETURNTYPE_ARRAYREFOFHASHREFS)
			{
			my $ra = $sth->fetchall_arrayref({});
			$ret = $ra;
			last;
			}
		$self->{LastError} = "_ExecuteQueryOnHandle(): Unknown return type '$nReturnType'";
		return undef;
		}
	$sth->finish();
	return $ret;
  }

sub _Create($$)
	{
	my ($proto, $self) = (shift, shift);

  my $class = ref($proto) || $proto;
  bless($self, $class);

  return $self;
	}

sub _MakeDsn
	{
	my ($nConnectionType, $sDatabaseName, $sHost) = (shift, shift, shift);
  if(not defined $nConnectionType)
    {
    $ConnectionError = "ConnectionType undefined at " . __FILE__ . " line " . __LINE__ . ".";
    return undef;
    }
  if(not defined $sDatabaseName)
    {
    $ConnectionError = "DatabaseName undefined at " . __FILE__ . " line " . __LINE__ . ".";
    return undef;
    }
  my $sDriverName = GetDriverName($nConnectionType);
  if(not defined $sDriverName)
    {
    $ConnectionError = "Can't get driver name for ConnectionType '$nConnectionType' at " . __FILE__ . " line " . __LINE__ . ".";
    return undef;
    }
  my $sDsn;
  SWITCH:
    {
    if($nConnectionType == CONNECTION_TYPE_MySQL)
      {
      $sDsn = "dbi:$sDriverName:$sDatabaseName";
      $sDsn .= ":$sHost"
        if(defined $sHost);
      last;
      }
    if($nConnectionType == CONNECTION_TYPE_ODBC)
      {
      $sDsn = "dbi:$sDriverName:$sDatabaseName";
      last;
      }
    if($nConnectionType == CONNECTION_TYPE_Postgres)
      {
      $sDsn = "dbi:$sDriverName:dbname=$sDatabaseName";
      $sDsn .= ":host=$sHost"
        if(defined $sHost);
      last;
      }
    if($nConnectionType == CONNECTION_TYPE_SQLite)
      {
      $sDsn = "dbi:$sDriverName:dbname=$sDatabaseName";
      last;
      }
    $ConnectionError = "Unknown ConnectionType '$nConnectionType' at " . __FILE__ . " line " . __LINE__ . ".";
    $sDsn = undef;
    }
  
  return $sDsn;
	}

=pod

Static functions

=cut

# Deprecated
sub GetMySQLDate
  {
  my ($nTime) = (shift);
	warn("GetMySQLDate() is deprecated");

	$nTime = time
		if(not defined $nTime);
	my ($nSecond, $nMinute, $nHour, $nDay, $nMonth, $nYear, $wday, $yday, $isdst) = gmtime($nTime);
	$nMonth++;
	$nYear += 1900;
	my $sMySQLDate = sprintf("%04u-%02u-%02u", $nYear, $nMonth, $nDay);
	return $sMySQLDate;
  }

# Deprecated
sub GetMySQLDateTime
  {
  my ($nTime) = (shift);
	warn("GetMySQLDateTime() is deprecated");

	$nTime = time
		if(not defined $nTime);
	my ($nSecond, $nMinute, $nHour, $nDay, $nMonth, $nYear, $wday, $yday, $isdst) = gmtime($nTime);
	$nMonth++;
	$nYear += 1900;
	my $sMySQLDate = sprintf("%04u-%02u-%02u %02u:%02u:%02u", $nYear, $nMonth, $nDay, $nHour, $nMinute, $nSecond);
	return $sMySQLDate;
  }

1;

__END__

=head1 NAME

Database::Wrapper - A truly unified perl database API, with a query cache

=head1 DESCRIPTION

Database::Wrapper papers over the cracks in the various DBD implementations.
Connection, schema queries and data queries have a unified interface.

=head1 Synopsis

  use Database::Wrapper qw(:RETURN_TYPES :CONNECTION_TYPES);

  my $rhConnection =
    {
    ConnectionType => CONNECTION_TYPE_MySQL,
    DatabaseName   => "MyDatabase",
    User           => "JRH",
    Password       => "PWD",
    Attribs        => {RaiseError => 0, PrintError => 0, AutoCommit => 0},
    };
  my $dbw = Database::Wrapper->new($rhConnection);
  die("Couldn't connect, $Database::Wrapper::ConnectionError")
    if(not defined $dbw);

	my $sqry = "SELECT * FROM foos;";
	$dbw->PrepareQuery("GetFoos", $sqry, RETURNTYPE_ARRAYREFOFHASHREFS);
	my $ra = $dbw->ExecuteQuery("GetFoos", []);

=head1 The API

=head2 Connection

=over 4

=item C<new()>

Connects to a database via DBI and DBD.

=head3 Parameters

=over 4

=item $class

The name of the class or an instance of a sub-class.

=over 4

=item $rhConnection

A hash containing the following items (obligatory marked '+', possible values given after ' => ', default indicated by '*'):

	+ConnectionType => (CONNECTION_TYPE_MySQL|CONNECTION_TYPE_ODBC|CONNECTION_TYPE_Postgres)
	+DatabaseName
	+User
	+Password
	Attribs				=> {RaiseError => (1*|0), PrintError => (1|0*), AutoCommit => (1*|0)}

=back

=head3 Returns:

The newly created instance, or C<undef> on failure.

If new() fails, the global variable '$ConnectionError' is set with an
error message.

=head3 Example:

  use Database::Wrapper qw(:RETURN_TYPES :CONNECTION_TYPES);

  my $rhConnection =
    {
    ConnectionType => CONNECTION_TYPE_MySQL,
    DatabaseName   => "MyDatabase",
    User           => "JRH",
    Password       => "PWD",
    Attribs        => {RaiseError => 0, PrintError => 0, AutoCommit => 0},
    };
  my $dbw = Database::Wrapper->new($rhConnection);
  die("Couldn't connect, $Database::Wrapper::ConnectionError")
    if(not defined $dbw);

=item Disconnection

Database handles are disconnected when they go out of scope, or are set to the undefined value.

  $dbw = undef;

=back

=head2 Query Caching

=over 4

=item C<PrepareQuery()>

Prepares a cached query.

=head3 Example:

	my $sqry = "SELECT * FROM foos;";
	$dbw->PrepareQuery("GetFoos", $sqry, RETURNTYPE_ARRAYREFOFHASHREFS);

Parameters:
	$sName
		The user's label for the prepared query.
		It is a good idea to use a format like "Package::Function" for these to avoid clashes.
	$nReturnType
		MUST be one of the values defined by the 'RETURNTYPE_*' constants:

=over 8

=item RETURNTYPE_NONE

Return nothing, whether the query succeeds or fails.

=item RETURNTYPE_SUCCESS

Return non-zero if the query succeeds.

=item RETURNTYPE_VALUE

Return the first field of the first record.

=item RETURNTYPE_ALLVALUES

Return an array of the first field of all records.

=item RETURNTYPE_HASHREF

Return the first record as a hash ref.

=item RETURNTYPE_ARRAYREF

Return the first record as an array ref.

=item RETURNTYPE_ARRAYREFOFHASHREFS

Return all records as hash refs.

=item RETURNTYPE_ARRAYREFOFARRAYREFS

Return all records as array refs.

=back

Return:
True - The query is ready to use.
False - Something is amiss. Call 'GetLastError()' to know more.

This function does NOT throw an error if the query has already been defined.
This wrapper is designed EXACTLY for this purpose.

A function can prepare it's queries WITHOUT having to worry if it has already done so.
The user should call 'QueryExists()' if he/she wants to know if a query has been prepared.

Furthermore, through careful use of the 'namespace' naming system (see above),
clashes should not happen.

=head3 $WarnDifferentPrepare

If the global '$WarnDifferentPrepare' is set to non-zero,
PrepareQuery() will emit a warning if it is called with an existing query name,
but with a different query.
Such a call is likely to indicate a programming error.

=item C<QueryExists()>

=item C<ExecuteQuery()>

=head3 Example:

	my $sqry = "SELECT * FROM foos;";
	$dbw->PrepareQuery("GetFoos", $sqry, RETURNTYPE_ARRAYREFOFHASHREFS);
	my $ra = $dbw->ExecuteQuery("GetFoos", []);

=back

=head2 Non-cached Queries

=over 4

=item C<ExecuteTemporaryQuery()>

Prepare and execute a temporary query

=head3 Example

  my $ra = $dbw->ExecuteTemporaryQuery("SELECT * FROM foo;", [], RETURNTYPE_ARRAYREFOFHASHREFS);

=item C<RunSql($self, $sql [, $reSplit])>

=over 4

=item C<$sql>

A string containing multiple SQL statements.

=item C<$reSplit>

Optional parameter. Sets the regular expression to use to split the SQL block into separate queries.
Default is /;[\r\n]+/.

=back

=head2 Utility Methods

=over 4

=item C<GetDatabaseNames()>

Can be called in the following ways:

1. (Deprecated) Static function
This function is not easy to remember and is MySQL specific.
  my $raDatabases = Database::Wrapper::GetDatabaseNames($nConnectionType, {user => XXX, password => YYY[, host => ZZZ][, port => PPP]});

2. Static function
This function takes a hash parameter which is the same as Database::Wrapper::new().
  my $raDatabases = Database::Wrapper::GetDatabaseNames($rhConnection);

3. Class method
The function can also be called on an instance of Database::Wrapper.
  my $raDatabases = $dbw->GetDatabaseNames();

The way that the 'data_sources' function works varies wildly:

MySQL

For MySQL, you MUST pass a user and password for a user with "SHOW TABLES" privileges.

'$rhAttribs' is undocumented by DBI.pm, but seems to be:
$rhAttribs =
	{
	user => ,
	password => ,
	[host => ,]
	[port => ,]
	}

Postgres

DBD::Pg connects to the 'template1' database, so the supplied user information
must be for a user with access privileges to that database.

=item C<DatabaseExists()>

See GetDatabaseNames() for parameters.

=item C<GetTableNames()>

=item C<GetMaxId()>

=back

=head2 Errors

=over 4

=item C<GetLastError()>

=back

=head2 Public Functions

=over 4

=item C<GetDriverName()>

The driver name is the string that follows 'DBI' in the connection string.

=back

=head1 COPYRIGHT

Copyright (C) 2003-2005 by Joe Yates, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
