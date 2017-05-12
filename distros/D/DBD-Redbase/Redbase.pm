###############################################################################
#
#                BUNGISOFT, INC.
#
#			      PROPRIETARY DATA
#
#  THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF
#  BUNGISOFT, INC. THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN
#  CONFIDENCE. INFORMATION CONTAINED HEREIN MAY NOT BE USED, COPIED OR
#  DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY WRITTEN AGREEMENT
#  SIGNED BY AN OFFICER OF BUNGISOFT, INC.
#
#  THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER
#  SECTIONS 104 AND 408 OF TITLE 17 OF THE UNITED STATES CODE.
#  UNAUTHORIZED USE, COPYING OR OTHER REPRODUCTION IS PROHIBITED BY LAW.
#
#  Copyright (c) 2002 Bungisoft, Inc.
#
#  Version: $Id: Redbase.pm,v 1.4 2003/10/22 02:53:55 ilya Exp $
#
###############################################################################
package DBD::Redbase;

use 5.006;
use strict;
use DBD::Redbase::DataStream;
use IO::Socket;

use vars qw($err $errstr $sqlstate $drh $VERSION @ISA $redbase_port $status_data $status_error $status_update);

$VERSION = '0.22';
$redbase_port = 6238;
$status_update = 0;
$status_error = 1;
$status_data = 2;

$err = 0;			#holds error code for DBI::err
$errstr = "";		#holds error string for DBI:errstr
$sqlstate = "";		#holds SQL state for DBI::state

$drh = undef;		#holds driver handle once initialized

sub driver($;$)
{
	return $drh if defined($drh);
	my ($class, $attr) = @_;

	$class .= "::dr";

	$drh = DBI::_new_drh($class,
		{
			'Name'        => 'Redbase',
			'Version'     => $VERSION,
			'Err'         => \$DBD::Redbase::err,
			'Errstr'      => \$DBD::Redbase::errstr,
			'State'       => \$DBD::Redbase::state,
			'Attribution' => 'DBD::Redbase by Bungisoft, Inc.',
		});

	return $drh;
}

###############################################################################
#	Driver package follows
###############################################################################
package DBD::Redbase::dr; # =========== Driver ==============

$DBD::Redbase::dr::imp_data_size = 0;

sub connect($$;$$$)
{
	my ($drh, $dbname, $user, $auth, $attr) = @_;
	my $dbh;
	my $var;
	my $port;
	my $host;
	my $socket;
	my $ds;



	#creating a "blank" dbh
	$dbh = DBI::_new_dbh($drh, {
			'Name'         => $dbname,
			'USER'         => $user,
			'CURRENT_USER' => $user,
		});


	#Process attributes from DSN; using ODBC syntax
	#i.e it looks like this:  var1=val1;...;varN=valN
	foreach $var (split(/;/, $dbname))
	{
		if ($var =~ /(.*)?=(.*)/)
		{
			$dbh->STORE("redbase_" . $1, $2);
		}
	}
	

	$dbh->STORE("redbase_port", $dbh->FETCH("redbase_port") || $DBD::Redbase::redbase_port);
	if (!$dbh->FETCH("redbase_host"))
	{
		return $dbh->DBI::set_err(1, "Host not specified");
	}
	

	#Connecting to the db
	$socket = IO::Socket::INET->new(PeerAddr => $dbh->FETCH("redbase_host"),
									PeerPort => $dbh->FETCH("redbase_port"),
									Proto    => "tcp"); 
	if (!defined($socket))
	{
		return $dbh->DBI::set_err(2, "Unable to establish connection (Host: " . $dbh->FETCH("redbase_host") . " Port: " . $dbh->FETCH("redbase_port") . ")");
	}
	$dbh->STORE("redbase_socket", $socket);
	

	$ds = new DBD::Redbase::DataStream($socket, $socket);
	$dbh->STORE("redbase_datastream", $ds);

	#Sending db our authentication
	$ds->writeUTF($user);
	$ds->writeUTF($auth);

	#Checking for success or failure is acctually delayed until the first
	#Query is executed due to the fact that Redbase does not report status of
	#the connection if it's successfull only if it's a failure

	return $dbh;
}

sub data_sources($$)
{
	return ();
}

sub disconnect_all($)
{
}

###############################################################################
#	Database package follows
###############################################################################
package DBD::Redbase::db;

$DBD::Redbase::db::imp_data_size = 0;

sub prepare($$;@)
{
	my ($dbh, $statement, @attr) = @_;
	my $sth;
	
	$sth = DBI::_new_sth($dbh, {'Statement' => $statement});

	if ($sth)
	{
		$sth->STORE('redbase_params', []);
		$sth->STORE('NUM_OF_PARAMS', ($statement =~ tr/?//));
	}

	return $sth;
}

#XXX retunr error if cannot close socket
sub disconnect($)
{
	my ($dbh) = @_;
	my $socket;
	my $ds;

	#Checking if we are in the AutoCommit mode that do a rollback on everything
	#That has not been finalized
	if (!$dbh->FETCH('AutoCommit'))
	{
		$dbh->STORE('RaiseError', 0);
		$dbh->rollback();
	}

	$socket = $dbh->FETCH("redbase_socket");
	return $socket->close();
}

sub FETCH($$)
{
	my ($dbh, $attr) = @_;

	if (($attr eq lc($attr)) || ($attr eq 'AutoCommit'))
	{
		return $dbh->{$attr};
	}
	else
	{
		return $dbh->DBD::_::db::FETCH($attr);
	}
}

sub STORE($$$)
{
	#Special handling required for AutoCommit
	my ($dbh, $attr, $value) = @_;


	if ($attr eq 'AutoCommit')
	{
		if($value && !$dbh->FETCH('AutoCommit'))
		{
			$dbh->do("SET AUTOCOMMIT TRUE");
		}
		elsif(!$value && $dbh->FETCH('AutoCommit'))
		{
			$dbh->do("SET AUTOCOMMIT FALSE");
		}

		$dbh->{$attr} = $value;
		return 1;
	}
	elsif ($attr eq lc($attr))
	{
		$dbh->{$attr} = $value;
		return 1;
	}
	else
	{
		return $dbh->DBD::_::db::STORE($attr, $value);
	}
}


#XXX Not implemented yet
sub type_info_all($)
{
	my ($dbh) = @_;
}

sub commit($)
{
	my ($dbh) = @_;
	if ($dbh->FETCH('AutoCommit'))
	{
		if ($dbh->FETCH('Warn'))
		{
			warn("Commit ineffective while AutoCommit is on", -1);
		}
		return 1;
	}
	else
	{
		return $dbh->do("COMMIT");
	}
}

sub rollback($)
{
	my ($dbh) = @_;
	if ($dbh->FETCH('AutoCommit'))
	{
		if ($dbh->FETCH('Warn'))
		{
			warn("Rollback ineffective while AutoCommit is on", -1);
		}
		return 0;
	}
	else
	{
		return $dbh->do("ROLLBACK");
	}
}

sub quote($$;$)
{
	my ($dbh, $str, $type) = @_;

	if (defined($type) &&
		(
			$type == DBI::SQL_NUMERIC()  ||
			$type == DBI::SQL_DECIMAL()  ||
			$type == DBI::SQL_INTEGER()  ||
			$type == DBI::SQL_SMALLINT() ||
			$type == DBI::SQL_FLOAT()    ||
			$type == DBI::SQL_REAL()     ||
			$type == DBI::SQL_DOUBLE()   ||
			$type == DBI::TINYINT()
		))
	{
		return $str;
	}
	elsif (!defined($str))
	{
		return "NULL";
	}
	else
	{
		$str =~ s/\\/\\\\/sg;
		$str =~ s/\0/\\0/sg;
		$str =~ s/\'/\\\'/sg;
		$str =~ s/\n/\\n/sg;
		$str =~ s/\r/\\r/sg;
		return "'$str'";
	}
}

sub DESTROY
{
	undef;
}

sub _list_tables($)
{
	my ($dbh) = @_;
	my $sth;
	my @tables = ();
	my $row;
	

	$sth = $dbh->prepare("SELECT table_name FROM system_tables");
	$sth->execute() || return undef;
	for(my $i = 0 ; ;$i++)
	{
		$row = $sth->fetch() || last;
		$tables[$i] = $row->[0];
	}

	return @tables;
}

###############################################################################
#	Statement package follows
###############################################################################
package DBD::Redbase::st;

$DBD::Redbase::st::imp_data_size = 0;

$DBD::Redbase::st::JDBC_types =
{
	-7 => "BIT",
	-6 => "TINYINT",
	5 => "SMALLINT",
	4 => "INTEGER",
	-5 => "BIGINT",
	6 => "FLOAT",
	7 => "REAL",
	8 => "DOUBLE",
	2 => "NUMERIC",
	3 => "DECIMAL",
	1 => "CHAR",
	12 => "VARCHAR",
	-1 => "LONGVARCHAR",
	91 => "DATE",
	92 => "TIME",
	93 => "TIMESTAMP",
	-2 => "BINARY",
	-3 => "VARBINARY",
	-4 => "LONGVARBINARY",
	0 => "NULL",
	1111 => "OTHER",
	2000 => "JAVA_OBJECT",
	2001 => "DISTINCT",
	2002 => "STRUCT",
	2003 => "ARRAY",
	2004 => "BLOB",
	2005 => "CLOB",
	2006 => "REF",
	70 => "DATALINK",
	16 => "BOOLEAN",
	100 => "VARCHAR_IGNORECASE",
};

sub bind_param($$$$)
{
	my ($sth, $pNum, $val, $attr) = @_;
	my $params;
	my $type;
	my $dbh;

	$type = (ref $attr)?$attr->{TYPE}:$attr;
	$dbh = $sth->{Database};
	$val = $dbh->quote($val, $type);

	$params = $sth->FETCH('redbase_params');
	$params->[$pNum - 1] = $val;

	return 1;
}

sub execute($@)
{
	my ($sth, @bind_values) = @_;
	my $statement;
	my $params;
	my $param_number;
	my $dbh;
	my $ds;
	my $mode;
	my $bytes;

	my @type;
	my @label;
	my @table;
	my @name;
	my $columns;
	my @data;
	my @nullable;

	#Getting database handle
	$dbh = $sth->{Database};

	#Doing parameter binding
	if (@bind_values == 0)
	{
		$params = $sth->FETCH('redbase_params');
	}
	else
	{
		#Quoting values
		map { $_ = $dbh->quote($_); } @bind_values;
		$params = \@bind_values;
	}

	$param_number = $sth->FETCH('NUM_OF_PARAMS');
	if ($params && (@$params != $param_number))
	{
		$sth->DBI::set_err(3, "Number of parameters passed to execute() method and sql statement does not match!");
		return 0;
	}

	$statement = $sth->{'Statement'};
	for(my $i = 0; $i < $param_number; $i++)
	{
		$statement =~ s/\?/$params->[$i]/e;
	}

	
	#At this point we have the statement with everything filled in already
	#and ready to rock and roll with the db
	$ds = $dbh->FETCH('redbase_datastream');

	#Sending statement to DB
	$ds->writeString($statement);

	#reading stuff from DB (Number of bytes in the next statment)
	$bytes = $ds->readInt();

	#Resetting bytecount on the DataStream to keep track of results
	$ds->resetByteCount();

	#Reading message code from DB
	$mode = $ds->readInt();

	#Was update statement
	if ($mode == $DBD::Redbase::status_update)
	{
		#Return number of rows affected
		my $affected = $ds->readInt();
		return ($affected)? $affected : '0E0';
	}
	#We had an error
	elsif ($mode == $DBD::Redbase::status_error)
	{
		my $errcode = $ds->readInt();
		my $errstring = $ds->readString();
		$sth->DBI::set_err($errcode, $errstring);
		return 0;
	}
	#Was select type of stattement
	else
	{
		$columns = $ds->readInt();

		#reading info
		for(my $i = 0; $i < $columns; $i++)
		{
			$type[$i] = $ds->readShort();
			$label[$i] = $ds->readString();
			$table[$i] = $ds->readString();
			$name[$i] = $ds->readString();
		}

		#Setting various attributes of sth
		
		#NUM_OF_FIELDS is read-only and should only be set once per
		#prepare thus this check in case we are passed * or something like it
		if (!$sth->FETCH('NUM_OF_FIELDS'))
		{
			$sth->STORE('NUM_OF_FIELDS', $columns);
		}
		if (!$sth->FETCH('NAME'))
		{
			$sth->STORE('NAME', \@name);
		}
		if(!$sth->FETCH('NULLABLE'))
		{
			@nullable = (2) x $columns;
			$sth->STORE('NULLABLE', \@nullable);
		}

		#$sth->trace_msg("Type  array ->" . join (":", @type) . "<-\n", 5);
		#$sth->trace_msg("Lable array ->" . join (":", @label) . "<-\n", 5);
		#$sth->trace_msg("Table array ->" . join (":", @table) . "<-\n", 5);
		#$sth->trace_msg("Name  array ->" . join (":", @name) . "<-\n", 5);
		#$sth->trace_msg("Starting data read, current byte value is: " . $ds->getByteCount() . "\n", 4);

		#Reading actual data
		#XXX
		#Maybe use some file on file system to buffer data, right now data
		#is stored in memory which may be a problem if the result set is large
		#or multiple result sets are present
		for(my $j = 0; $ds->getByteCount() < $bytes; $j++)
		{
			#$sth->trace_msg("Current row #" . ($j + 1) . " current byte count:" . $ds->getByteCount . " expected finish byte count:" . $bytes . "\n", 4);

			my @row = ();
			for(my $i = 0; $i < $columns; $i++)
			{
				#checking if column is null
				if ($ds->readByte() == 0)
				{
					$row[$i] = undef; #NULL value
					next;
				}

				#Readin different datatypes
				foreach($DBD::Redbase::st::JDBC_types->{$type[$i]})
				{
					(/CHAR/ || /VARCHAR/ || /LONGVARCHAR/ || /VARCHAR_IGNORECASE/) && do
						{
							#$sth->trace_msg("Start read CHAR/VARCHAR/LONGVARCHAR - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readString();

							#$sth->trace_msg("End   read CHAR/VARCHAR/LONGVARCHAR - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/TINYINT/ || /SMALLINT/) && do
						{
							#$sth->trace_msg("Start read TINYINT/SMALLINT - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readShort();

							#$sth->trace_msg("End   read TINYINT/SMALLINT - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/INTEGER/) && do
						{
							#$sth->trace_msg("Start read INTEGER - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readInt();

							#$sth->trace_msg("End   read INTEGER - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/BIGINT/) && do
						{
							#$sth->trace_msg("Start read BIGINT - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readLong();

							#$sth->trace_msg("End   read BIGINT - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/REAL/ || /FLOAT/ || /DOUBLE/) && do
						{
							#$sth->trace_msg("Start read REAL/FLOAT/DOUBLE - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readDouble();

							#$sth->trace_msg("End   read REAL/FLOAT/DOUBLE - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/NUMERIC/ || /DECIMAL/) && do
						{
							#$sth->trace_msg("Start read NUMERIC/DECIMAL - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readDecimal();

							#$sth->trace_msg("End   read NUMERIC/DECIMAL - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/BIT/) && do
						{
							#$sth->trace_msg("Start read BIT - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readBoolean();

							#$sth->trace_msg("End   read BIT - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/DATE/) && do
						{
							#$sth->trace_msg("Start read DATE - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readDate();

							#$sth->trace_msg("End   read DATE - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/^TIME$/) && do
						{
							#$sth->trace_msg("Start read TIME - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readTime();

							#$sth->trace_msg("End   read TIME - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/^TIMESTAMP$/) && do
						{
							#$sth->trace_msg("Start read TIMESTAMP - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readTimestamp();

							#$sth->trace_msg("End   read TIMESTAMP - End Bytes: " . $ds->getByteCount . "\n", 6);
						};
					(/OTHER/ || /BINARY/ || /VARBINARY/ || /LONGVARBINARY/) && do
						{
							#$sth->trace_msg("Start read OTHER - Beg Bytes: " . $ds->getByteCount . "\n", 6);

							$row[$i] = $ds->readByteArray();

							#$sth->trace_msg("Start read OTHER - Beg Bytes: " . $ds->getByteCount . "\n", 6);
						};
				}
			}
			
			#$sth->trace_msg("Current row ->" . join(":", @row) . "<-\n", 4);

			$data[$j] = \@row;
		}

		$sth->{'redbase_data'} = \@data;
		$sth->{'redbase_rows'} = @data;


		return @data || '0E0';
	}
}

sub fetch($)
{
	my ($sth) = @_;
	my $data;
	my $row;

	$data = $sth->FETCH('redbase_data');
	$row = shift @{$data};
	if (!$row)
	{
		return undef;
	}

	if ($sth->FETCH('ChopBlanks'))
	{
		map { $_ =~ s/\s+$//; } @$row;
	}

	return  $sth->_set_fbav($row);
}

*fetchrow_arrayref = \&fetch;

sub rows($)
{
	my ($sth) = @_;

	return $sth->FETCH('redbase_rows');
}

sub finish($)
{
	my ($sth) = @_;

	undef $sth->{'redbase_data'};
	undef $sth->{'redbase_rows'};
	$sth->DBD::_::st::finish();
	return 1;
}

sub FETCH($$)
{
	my ($sth, $attr) = @_;

	if ($attr eq 'NAME')
	{
		return $sth->{NAME};
	}
	elsif ($attr eq 'NULLABLE')
	{
		return $sth->{NULLABLE};
	}
	elsif ($attr eq lc($attr))
	{
		return $sth->{$attr};
	}
	else
	{
		return $sth->DBD::_::st::FETCH($attr);
	}
}

sub STORE($$$)
{
	my ($sth, $attr, $value) = @_;


	if ($attr eq 'NAME')
	{
		if (defined($sth->{NAME}))
		{
			$sth->DBI::set_err(4, "NAME attribute of statement handle has already been set!");
			return 0;
		}
		else
		{
			$sth->{NAME} = $value;
			return 1;
		}
	}
	elsif ($attr eq 'NULLABLE')
	{
		if (defined($sth->{NULLABLE}))
		{
			$sth->DBI::set_err(4, "NULLABLE attribute of statement handle has already been set!");
			return 0;
		}
		else
		{
			$sth->{NULLABLE} = $value;
			return 1;
		}
	}
	elsif ($attr eq lc($attr))
	{
		$sth->{$attr} = $value;
	}
	else
	{
		return $sth->DBD::_::st::STORE($attr, $value);
	}
}

sub DESTROY($)
{
	undef;
}

1;
__END__
