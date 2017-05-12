# $Id: PrimeBase.pm,v 1.4001 2001/07/30 19:29:50
# Copyright (c) 2001  Snap Innovation
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
$DBD::PrimeBase::VERSION = '1.4003';

{
    package DBD::PrimeBase;

    use DBI ();
    use DynaLoader ();
    @ISA = qw(DynaLoader);

    my $Revision = substr(q$Revision: 1.00 $, 1);

    require_version DBI 1.02;

    bootstrap DBD::PrimeBase $VERSION;

    $err = 0;		# holds error code   for DBI::err    (XXX SHARED!)
    $errstr = "";	# holds error string for DBI::errstr (XXX SHARED!)
    $drh = undef;	# holds driver handle once initialised

    sub driver{
		return $drh if $drh;
		my($class, $attr) = @_;

		$class .= "::dr";

		# not a 'my' since we use it above to prevent multiple drivers

		$drh = DBI::_new_drh($class, {
		    'Name' => 'PrimeBase',
		    'Version' => $VERSION,
		    'Err'    => \$DBD::PrimeBase::err,
		    'Errstr' => \$DBD::PrimeBase::errstr,
		    'Attribution' => "DBD::PrimeBase $VERSION",
		    });

		$drh;
    }


    1;
}


{   package DBD::PrimeBase::dr; # ====== DRIVER ======
    use strict;


    sub connect {
		my ($drh, $dbname, $user, $auth, $attr)= @_;


		# create a 'blank' dbh

		my $dbh = DBI::_new_dbh($drh, {
		    'Name' => $dbname,
		    'USER' => $user, 'CURRENT_USER' => $user,
		    });

		DBD::PrimeBase::db::_login($dbh, $dbname, $user, $auth)
		    or return undef;


		$dbh;
    }

	sub admin {
	    my($drh) = shift;
	    my($command) = shift;
	    my($dbname) = ($command eq 'createdb'  ||  $command eq 'dropdb') ?
		shift : '';
	    my($host) = shift || '';
	    my($server) = shift || '';
	    my($user) = shift || '';
	    my($password) = shift || '';
	
	    	$drh->func(undef, $command,
				$dbname || '',
				$host || '',
				$server || '',
				$user, $password, '_admin_internal');
	}

}


{   package DBD::PrimeBase::db; # ====== DATABASE ======
    use strict;

  
	sub admin {
	    my($dbh) = shift;
	    my($command) = shift;
	    my($dbname) = ($command eq 'createdb'  ||  $command eq 'dropdb') ?
		shift : '';
	    $dbh->{'Driver'}->func($dbh, $command, $dbname, '', '', '',
				   '_admin_internal');
	}

  sub prepare {
		my($dbh, $statement, @attribs)= @_;

		# create a 'blank' dbh
		my $sth = DBI::_new_sth($dbh, {
		    'Statement' => $statement,
		    });

		# Call PrimeBase func in PrimeBase.xs file.
		# and populate internal handle data.

		DBD::PrimeBase::st::_prepare($sth, $statement, @attribs)
		    or return undef;

		$sth;
    }




    sub table_info {
		my($dbh) = @_;		# XXX add qualification

		# create a "blank" statement handle
		my $sth = DBI::_new_sth($dbh, { 'Statement' => "PBITables" });

		DBD::PrimeBase::st::_proc_call($sth, "table_info();")
			or return undef;
		$sth;
   }


    sub ping {
		my($dbh) = @_;
		my $ok = 0;
		local $SIG{__WARN__} = sub { } if $dbh->{PrintError};
		eval {
		    my $sth =  $dbh->prepare("describe databases");
		    # A describe databases should do the trick. 
		    $ok = $sth && $sth->execute;
		};
		return ($@) ? 0 : $ok;
    }

	
    sub type_info_all {
		my ($dbh) = @_;
		my $names = {
	          TYPE_NAME		=> 0,
	          DATA_TYPE		=> 1,
	          COLUMN_SIZE		=> 2,
	          LITERAL_PREFIX	=> 3,
	          LITERAL_SUFFIX	=> 4,
	          CREATE_PARAMS		=> 5,
	          NULLABLE		=> 6,
	          CASE_SENSITIVE	=> 7,
	          SEARCHABLE		=> 8,
	          UNSIGNED_ATTRIBUTE	=> 9,
	          FIXED_PREC_SCALE	=>10,
	          AUTO_UNIQUE_VALUE	=>11,
	          LOCAL_TYPE_NAME	=>12,
	          MINIMUM_SCALE		=>13,
	          MAXIMUM_SCALE		=>14,
	        };
		my $ti = [
		  $names,
	            [ 'VARCHAR', 12, 32000, '\'', '\'', 'max length', 1, 1, 3, undef, 0,undef, undef, undef, undef ],
				[ 'TIMESTAMP', 11, 22, undef, undef, undef, 1, 0, 2, undef, 0,undef, undef, 0, 2 ],
				[ 'TIME', 10, 8, undef, undef, undef, 1, 0, 2, undef, 0, undef,undef, undef, undef ],
				[ 'DATE', 9, 10, undef, undef, undef, 1, 0, 2, undef, 0, undef,undef, undef, undef ],
				[ 'DOUBLE', 8, 15, undef, undef, undef, 1, 0, 2, 0, 0, 0, undef,undef, undef ],
				[ 'REAL', 7, 7, undef, undef, undef, 1, 0, 2, 0, 0, 0, undef,undef, undef ],
				[ 'FLOAT', 6, 15, undef, undef, undef, 1, 0, 2, 0, 0, 0, undef,undef, undef ],
				[ 'SMINT', 5, 5, undef, undef, undef, 1, 0, 2, 0, 0, 0, undef,undef, undef ],
				[ 'INT', 4, 10, undef, undef, undef, 1, 0, 2, 0, 0, 0, undef,undef, undef ],
				[ 'DECIMAL', 3, 60, undef, undef, 'precision,scale', 1, 0, 2, 0, 0, 0,undef, 0, 60 ],
				[ 'CHAR', 1, 32000, '\'', '\'', 'max length', 1, 1, 3, undef, 0, undef,undef, undef, undef ],
				[ 'LONGCHAR', -1, undef, '\'', '\'', undef, 1, 0, 0, undef, 0, undef,undef, undef, undef ],
				[ 'BINARY', -2, 32000, '\'', '\'', 'max length', 1, 0, 2, undef, 0, undef,undef, undef, undef ],
				[ 'VARBIN', -3, 32000, '\'', '\'', 'max length', 1, 0, 2, undef, 0, undef,undef, undef, undef ],
				[ 'LONGBIN', -4, undef, '\'', '\'', undef, 1, 0, 0, undef, 0, undef,undef, undef, undef ],
				[ 'TINYINT', -6, 3, undef, undef, undef, 1, 0, 2, 1, 0, 0, undef,undef, undef ],
				[ 'BOOLEAN', -7, 1, undef, undef, undef, 1, 0, 2, undef, 0,undef, undef, undef, undef ],
	            [ 'WCHAR', -8, 32000, '\'', '\'', 'max length', 1, 1, 3, undef, 0,undef, undef, undef, undef ]
	        ];
	return $ti;
    }


}

{   package DBD::PrimeBase::st; # ====== STATEMENT ======

    # all done in XS
}


1;
__END__

=head1 NAME

DBD::PrimeBase - PrimeBase database server driver for DBI

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect('dbi:PrimeBase:Server=$SName;Address=$IPNUM;Database=$DBName', 'user', 'password');
 
  where:
    $SName is the PrimeBase server name, for example "PrimeServer". 
    $IPNUM is the IP address of the machine on which the PrimeBase server is running. Default "localhost"
    $DBName is the name of the database to be connected to.
     

See L<DBI> for more information.

=head1 DESCRIPTION

The PrimeBase Driver for DBI was created by taking the ODBC driver and converting it so that it used
the PrimeBase API instead of ODBC. The Oracle and mysql DBDs were also used as a reference while doing this.

This is a first pass at the PrimeBase DBD and it is hoped that it will be enough to introduce
PrimeBase to the Perl community. If you find bugs or missing features please report them to
support@PrimeBase.com or mention them in the PrimeBase talk mail list where they will be looked at
and fixed. To subscribe to the PrimeBase talk mail list send mail to : PrimeBase-Talk-on@lists.imd.net

=head2 Server Administration

=over 4

=item admin

    $rc = $drh->func("createdb", $dbname, [host, user, password,], 'admin');
    $rc = $drh->func("dropdb", $dbname, [host, user, password,], 'admin');



=over 4

=item createdb

Creates the database $dbname if it doesn't already exist. 

=item dropdb

Drops the database $dbname. 

It should be noted that database deletion is
I<not prompted for> in any way.  Nor is it undo-able.

Once you drop the database, the database and all data in it will be gone!

This method should be used at your own risk.

=back

=back

=head1 DATABASE HANDLES

The DBD::PrimeBase driver supports the following attributes of database
handles :

=item Transaction Handling

=over 4

=item $dbh->{AutoCommit} = 0;

Starts a transaction.

=item $dbh->commit;

Commits changes made in the transaction.

=item $dbh->rollback;

Undo changes made in the transaction.
 
=item $dbh->{AutoCommit} = 1;

Each statement is treated as a separate transaction
which is committed automatically on successful completion.
This also has the effect of committing any previous
transaction.

=back

=head2 NON STANDARD DATABASE HANDLES ATTRIBUTES

=over 4

=item pb_datefmt (string, read/write)

The format for string representations of date data. 
For example "MM/DD/YYYY".

Please refer to the "PrimeBase Talk User Guide" under $datefmt for more information.

=item pb_timefmt (string, read/write)

The format for string representations of time data. 
For example "HH:MM:SS:hu".

Please refer to the "PrimeBase Talk User Guide" under $timefmt for more information.

=item pb_datetimefmt (string, read/write)

The format for string representations of datetime data. 
For example "MM/DD/YYYY HH:MM:SS".

Please refer to the "PrimeBase Talk User Guide" under $tsfmt for more information.

=item 	pb_tracing (bool, write)

Activates the API logging in the PrimeBase virtual machine.
This can be useful in debugging or reporting problems. 

=item 	pb_tracelog (string, write)

Set the name of the log file to use for API logging.

=item 	pb_dbd_tracing (string, write)

Activates tracing in the PrimeBase DBD. Output will be written to the file
'DBDTrace.log' in the current working directory.
This can be useful in debugging or reporting problems. 


=back


=head1 STATEMENT HANDLES

The DBD::PrimeBase driver supports the following standard attributes of statement
handles :

=over 4

=item ChopBlanks

=item LongReadLen

=item LongTruncOk

=item NUM_OF_PARAMS

=item NUM_OF_FIELDS

=item NAME

=item CursorName

=item TYPE

=item PRECISION

=item SCALE

=back

Please refer to the DBI documentation for a description of these attributes.



=head1 ACKNOWLEDGEMENTS

Thanks to all the people who created the original ODBC, Mysql, and Oracle DBDs.


=cut
