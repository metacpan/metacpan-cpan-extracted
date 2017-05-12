# $Id: ODBC.pm,v 1.12 1998/08/14 19:29:50 timbo Exp $
#
# Copyright (c) 1994,1995,1996,1998  Tim Bunce
# portions Copyright (c) 1997,1998,1999,2000,2001,2002  Jeff Urlwin
# portions Copyright (c) 1997  Thomas K. Wenrich
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

require 5.004;

$DBD::Mimer::VERSION = '1.00';

{
    package DBD::Mimer;

    use DBI ();
    use DynaLoader ();

    @ISA = qw(DynaLoader);
    use Exporter ();

    my $Revision = substr(q$Revision: 1.12 $, 10);

    require_version DBI 1.21;

    bootstrap DBD::Mimer $VERSION;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $sqlstate = "00000";
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'Mimer',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::Mimer::err,
	    'Errstr' => \$DBD::Mimer::errstr,
	    'State' => \$DBD::Mimer::sqlstate,
	    'Attribution' => 'DBD for Mimer SQL (Upright Database Technology and Jeff Urlwin)',
	    });

	$drh;
    }

    sub CLONE { undef $drh  }
    1;
}


{   package DBD::Mimer::dr; # ====== DRIVER ======
    use strict;

    sub connect {
	my $drh = shift;
	my($dbname, $user, $auth, $attr)= @_;
	$user = '' unless defined $user;
	$auth = '' unless defined $auth;

	# create a 'blank' dbh
	my $this = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'USER' => $user, 
	    'CURRENT_USER' => $user,
	    });

	# Call ODBC logon func in Mimer.xs file
	# and populate internal handle data.

	DBD::Mimer::db::_login($this, $dbname, $user, $auth, $attr) or return undef;

	$this;
    }

    sub data_sources {
	my $drh = shift;
	return sql_data_sources($drh) if ($^O eq "MSWin32" || $^O eq "cygwin");

	my $sqlhosts = "/etc/sqlhosts";
	$sqlhosts = "MIMER_SQLHOSTS" if ($^O eq "VMS");

	my @res = ();

	open(SQLHOSTS,$sqlhosts) || return sql_data_sources($_);
	my $section = "";
	while (<SQLHOSTS>) {
	    s/(^([^-]|-[^-])*)--.*$/$1/;
	    $section = "LOCAL" if (/LOCAL:/);
	    $section = "REMOTE" if (/REMOTE:/);
	    next if ($section ne "LOCAL" && $section ne "REMOTE");

	    if (/^[ \t]+(\w+)[ \t]+([^ \t]+)/) {
		push(@res,$1);
	    } 
	}
	close(SQLHOSTS);

	return @res;
    }

}


{   package DBD::Mimer::db; # ====== DATABASE ======
    use strict;

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' dbh
	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call ODBC func in Mimer.xs file.
	# (This will actually also call SQLPrepare for you.)
	# and populate internal handle data.

	DBD::Mimer::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }

    sub column_info {
	my ($dbh, $catalog, $schema, $table, $column) = @_;

	$catalog = "" if (!$catalog);
	$schema = "" if (!$schema);
	$table = "" if (!$table);
	$column = "" if (!$column);
	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLColumns" });

	_columns($dbh,$sth, $catalog, $schema, $table, $column)
	    or return undef;

	$sth;
    }
    

    sub columns {
	my ($dbh, $catalog, $schema, $table, $column) = @_;

	$catalog = "" if (!$catalog);
	$schema = "" if (!$schema);
	$table = "" if (!$table);
	$column = "" if (!$column);
	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLColumns" });

	_columns($dbh,$sth, $catalog, $schema, $table, $column)
	    or return undef;

	$sth;
    }


    sub table_info {
 	my($dbh, $catalog, $schema, $table, $type) = @_;

	if ($#_ == 1) {
	   my $attrs = $_[1];
	   $catalog = $attrs->{TABLE_CAT};
	   $schema = $attrs->{TABLE_SCHEM};
	   $table = $attrs->{TABLE_NAME};
	   $type = $attrs->{TABLE_TYPE};
 	}

	$catalog = "" if (!$catalog);
	$schema = "" if (!$schema);
	$table = "" if (!$table);
	$type = "" if (!$type);

	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLTables" });

	DBD::Mimer::st::_tables($dbh,$sth, $catalog, $schema, $table, $type)
	      or return undef;
	$sth;
    }

    sub primary_key_info {
       my ($dbh, $catalog, $schema, $table ) = @_;
 
       # create a "blank" statement handle
       my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLPrimaryKeys" });
 
       $catalog = "" if (!$catalog);
       $schema = "" if (!$schema);
       $table = "" if (!$table);
       DBD::Mimer::st::_primary_keys($dbh,$sth, $catalog, $schema, $table )
	     or return undef;
       $sth;
    }

    sub foreign_key_info {
       my ($dbh, $pkcatalog, $pkschema, $pktable, $fkcatalog, $fkschema, $fktable ) = @_;
 
       # create a "blank" statement handle
       my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLForeignKeys" });
 
       $pkcatalog = "" if (!$pkcatalog);
       $pkschema = "" if (!$pkschema);
       $pktable = "" if (!$pktable);
       $fkcatalog = "" if (!$fkcatalog);
       $fkschema = "" if (!$fkschema);
       $fktable = "" if (!$fktable);
       _GetForeignKeys($dbh, $sth, $pkcatalog, $pkschema, $pktable, $fkcatalog, $fkschema, $fktable) or return undef;
       $sth;
    }

    sub ping {
	my $dbh = shift;
	my $state = undef;

 	my ($catalog, $schema, $table, $type);

	$catalog = "";
	$schema = "";
	$table = "NOXXTABLE";
	$type = "";

	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLTables_PING" });

	DBD::Mimer::st::_tables($dbh,$sth, $catalog, $schema, $table, $type)
	      or return 0;
	$sth->finish;
	return 1;

    }

    sub oldping {
	my $dbh = shift;
	my $state = undef;
	# should never 'work' but if it does, that's okay!
	# JLU incorporated patches from Jon Smirl 5/4/99
	{
	    local $dbh->{RaiseError} = 0 if $dbh->{RaiseError};
	    # JLU added local PrintError handling for completeness.
	    # it shouldn't print, I think.
	    local $dbh->{PrintError} = 0 if $dbh->{PrintError};
	    my $sql = "select sysdate from dual1__NOT_FOUND__CANNOT";
	    my $sth = $dbh->prepare($sql);
	    # fixed "my" $state = below.  Was causing problem with
	    # ping!  Also, fetching fields as some drivers (Oracle 8)
	    # may not actually check the database for activity until
	    # the query is "described".
	    # Right now, Oracle8 is the only known version which
	    # does not actually check the server during prepare.
	    my $ok = $sth && $sth->execute();

	    $state = $dbh->state;
	    $DBD::Mimer::err = 0;
	    $DBD::Mimer::errstr = "";
	    $DBD::Mimer::sqlstate = "00000";
	    return 1 if $ok;
	}
	return 1 if $state eq 'S0002';	# Base table not found
 	return 1 if $state eq '42S02';  # Base table not found.Solid EE v3.51
	return 1 if $state eq 'S0022';	# Column not found
	return 1 if $state eq '37000';  # statement could not be prepared (19991011, JLU)
	# return 1 if $state eq "S1000';  # General Error? ? 5/30/02
	# We assume that any other error means the database
	# is no longer connected.
	# Some special cases may need to be added to the code above.
	return 0;
    }

    # New support for the next DBI which will have a get_info command.
    # leaving support for ->func(xxx, GetInfo) (above) for a period of time
    # to support older applications which used this.
    sub get_info {
	my ($dbh, $item) = @_;
	# handle SQL_DRIVER_HSTMT, SQL_DRIVER_HLIB and
	# SQL_DRIVER_HDESC specially
	if ($item == 5 || $item == 135 || $item == 76) {
	   return undef;
	}
	return _GetInfo($dbh, $item);
    }

    # new override of do method provided by Merijn Broeren
    # this optimizes "do" to use SQLExecDirect for simple
    # do statements without parameters.
    sub do {
        my($dbh, $statement, $attr, @params) = @_;
        my $rows = 0;

        if( -1 == $#params )
        {
          # No parameters, use execute immediate
          $rows = ExecDirect( $dbh, $statement );
          if( 0 == $rows )
          {
            $rows = "0E0";
          }
          elsif( $rows < -1 )
          {
            undef $rows;
          }
        }
        else
        {
          $rows = $dbh->SUPER::do( $statement, $attr, @params );
        }
        return $rows
    }

    #
    # can also be called as $dbh->func($sql, ExecDirect);
    # if, for some reason, there are compatibility issues
    # later with DBI's do.
    #
    sub ExecDirect {
       my ($dbh, $sql) = @_;
       _ExecDirect($dbh, $sql);
    }

    # Call the ODBC function SQLGetInfo
    # Args are:
    #	$dbh - the database handle
    #	$item: the requested item.  For example, pass 6 for SQL_DRIVER_NAME
    # See the ODBC documentation for more information about this call.
    #
    sub GetInfo {
	my ($dbh, $item) = @_;
	get_info($dbh, $item);
    }

    # Call the ODBC function SQLStatistics
    # Args are:
    # See the ODBC documentation for more information about this call.
    #
    sub GetStatistics {
			my ($dbh, $Catalog, $Schema, $Table, $Unique) = @_;
			# create a "blank" statement handle
			my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLStatistics" });
			_GetStatistics($dbh, $sth, $Catalog, $Schema, $Table, $Unique) or return undef;
			$sth;
    }

    # Call the ODBC function SQLForeignKeys
    # Args are:
    # See the ODBC documentation for more information about this call.
    #
    sub GetForeignKeys {
			my ($dbh, $PK_Catalog, $PK_Schema, $PK_Table, $FK_Catalog, $FK_Schema, $FK_Table) = @_;
			# create a "blank" statement handle
			my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLForeignKeys" });
			_GetForeignKeys($dbh, $sth, $PK_Catalog, $PK_Schema, $PK_Table, $FK_Catalog, $FK_Schema, $FK_Table) or return undef;
			$sth;
    }

    # Call the ODBC function SQLPrimaryKeys
    # Args are:
    # See the ODBC documentation for more information about this call.
    #
    sub GetPrimaryKeys {
			my ($dbh, $Catalog, $Schema, $Table) = @_;
			# create a "blank" statement handle
			my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLPrimaryKeys" });
			_GetPrimaryKeys($dbh, $sth, $Catalog, $Schema, $Table) or return undef;
			$sth;
    }

    # Call the ODBC function SQLSpecialColumns
    # Args are:
    # See the ODBC documentation for more information about this call.
    #
    sub GetSpecialColumns {
	my ($dbh, $Identifier, $Catalog, $Schema, $Table, $Scope, $Nullable) = @_;
	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLSpecialColumns" });
	_GetSpecialColumns($dbh, $sth, $Identifier, $Catalog, $Schema, $Table, $Scope, $Nullable) or return undef;
	$sth;
    }
	
    sub GetTypeInfo {
	my ($dbh, $sqltype) = @_;
	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
	# print "SQL Type is $sqltype\n";
	_GetTypeInfo($dbh, $sth, $sqltype) or return undef;
	$sth;
    }

    sub type_info_all {
	my ($dbh, $sqltype) = @_;
	$sqltype = DBI::SQL_ALL_TYPES unless defined $sqltype;
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
	_GetTypeInfo($dbh, $sth, $sqltype) or return undef;
	my $info = $sth->fetchall_arrayref;
	unshift @$info, {
	    map { ($sth->{NAME}->[$_] => $_) } 0..$sth->{NUM_OF_FIELDS}-1
	};
	return $info;
    }

}


{   package DBD::Mimer::st; # ====== STATEMENT ======
    use strict;

    sub ColAttributes {		# maps to SQLColAttributes
	my ($sth, $colno, $desctype) = @_;
	# print "before ColAttributes $colno\n";
	my $tmp = _ColAttributes($sth, $colno, $desctype);
	# print "After ColAttributes\n";
	$tmp;
    }

    sub cancel {
	my $sth = shift;
	my $tmp = _Cancel($sth);
	$tmp;
    }
}

1;
__END__

=head1 NAME

DBD::Mimer - Mimer SQL Driver for DBI

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect('dbi:Mimer:DSN', 'user', 'password');

See L<DBI> for more information.

=head1 DESCRIPTION

DBD::Mimer is a Perl5 database interface for the Mimer SQL
database.

Using this module is one of several ways of accessing Mimer SQL 
from the Perl programming language. The most portable way is
to use DBD::ODBC through a driver manager. The driver manager
offers an abstraction layer which improves portability. In some
situations, using a driver manager is not feasible. This could be true
because you don't want to install a driver manager on your system,
or that there is no driver manager available for your type of system.

DBD::Mimer offers the same features as DBD::ODBC but links statically
with the Mimer ODBC driver, thus skipping the driver manager. 

Most of the code, build scripts and documentation is derived from
DBD::ODBC. Development of DBD::Mimer will not extend beyond features
offered by DBD::ODBC. This way, anyone using DBD::Mimer can easily switch 
to DBD::ODBC when a driver manager is preferred.

=head2 Recent Updates

=over 4
=item B<DBD::Mimer 1.00>

 This is the first DBD::Mimer release. 

 Most of the code has been forked from DBD::ODBC 1.06. Our compliments
 to the original author and subsequent maintainers. Code was added to
 handle Mimer data sources. Tests, included in DBD::ODBC, not coded
 against SQL-99 was dropped. Some tests in DBD::ODBC was hardcoded
 using Microsoft SQL Server and Oracle specific SQL constructs.
 
=back

=cut

























