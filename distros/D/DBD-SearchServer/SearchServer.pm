#
#	Project		: DBD::SearchServer
#	Module/Library	: 
#	Author		: $Author: shari $
#	Revision	: $Revision: 2.20 $
#	Check-in date	: $Date: 1999/03/04 10:59:40 $
#	Locked by	: $Locker:  $
#
#	----------------
#	Copyright	:
#	$Id: SearchServer.pm,v 2.20 1999/03/04 10:59:40 shari Exp $ (c) 1996-98, Davide Migliavacca and Inferentia (Milano) IT
#	
#	Description	:

$DBD::SearchServer::VERSION = '0.21';


{
    package DBD::SearchServer;

    use DBI ();
    use DynaLoader ();
    use Exporter ();
    @ISA = qw(Exporter DynaLoader);
	
    my $Revision = substr(q$Revision: 2.20 $, 10);
    require_version DBI 1.00 ;

    bootstrap DBD::SearchServer $VERSION;

    #use SearchServer::Constants;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $state = "";	# DBI::state information

    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	unless ($ENV{FULCRUM_HOME}){
		$ENV{FULCRUM_HOME} = "/home/fulcrum";
	    my $msg = "set to $ENV{FULCRUM_HOME}"; 
	    warn "FULCRUM_HOME $msg\n";
	}

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class,
			     {
			      'Name' => 'SearchServer',
			      'Version' => $VERSION,
			      'Err'     => \$DBD::SearchServer::err,
			      'Errstr'  => \$DBD::SearchServer::errstr,
			      'State'   => \$DBD::SearchServer::state,
			      'Attribution' => 'PCDOCS/Fulcrum SearchServer DBD by Davide Migliavacca',
			     }
			    );

	$drh;
    }

    1;
}


{   package DBD::SearchServer::dr; # ====== DRIVER ======
    use strict;

    sub connect {
       	my ($drh, $dbname, $user, $auth, $attr)= @_;

	if ($dbname){	# application is asking for specific database
	   # no use
	}

	# create a 'blank' dbh

	my $dbh = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'USER' => $user,
	    'CURRENT_USER' => $user,
	    });

	DBD::SearchServer::db::_login($dbh, $dbname, $user, $auth)
	    or return undef;

	

	$dbh;
    }
    

}


{   package DBD::SearchServer::db; # ====== DATABASE ======
    use strict;

    sub prepare {
	my($dbh, $statement,@attribs)= @_;

	# create a 'blank' dbh

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	DBD::SearchServer::st::_prepare($sth, $statement,@attribs)
	    or return (undef);

	$sth;
    }
    
    sub table_info {
       my($dbh) = @_;		# XXX add qualification
       my $sth = $dbh->prepare("select
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		TABLE_TYPE,
		REMARKS
	    from TABLES
	    order by TABLE_TYPE, TABLE_OWNER, TABLE_NAME") or return undef;
       $sth->execute or return undef;
       $sth;
    }

}


{   package DBD::SearchServer::st; # ====== STATEMENT ======

    # all in XS

}

1;

__END__

=head1 NAME

DBD::SearchServer - PCDOCS/Fulcrum SearchServer database driver for the DBI module

=head1 SYNOPSIS

  use DBI;
  use DBD::SearchServer;

  $ss_dbh = DBI->connect('dbi:SearchServer:', $user, $passwd);
	# use $ENV{FULSEARCH} for "instance", $user and $pass normally empty


  # See the DBI module documentation for full details

=head1 DESCRIPTION

DBD::SearchServer is a Perl module which works with the DBI module to provide
access to PCDOCS/Fulcrum SearchServer data sources.
This module was named DBD::Fulcrum until March 1999.

=head1 REQUIREMENTS
SearchServer 2.x and beyond (lately tested only on 3.5)
on
   IBM AIX 3.2.5, 4.1.5;
   Digital OSF/1 3.2c, Digital Unix 4.0x,
   Solaris 2.5.1, 2.6 Sparc,
   Solaris 2.4 (reported from user),
   Windows NT 4.0sp3,
   HP-UX 10.20, 11.00

   You'll need the SearchServer C SDK to build this driver.

=head1 ENVIRONMENT

As a PCDOCS/Fulcrum SearchServer SDK application, this driver will use the environment
to determine its operating specifications:
	FULSEARCH
	FULCREATE
	FULTEMP
will generally be needed.
For NT, use the DBI_DSN environment variable prevails.
Please consult Fulcrum docs for more information or refer to test.pl for real-world use.

=head1 CAVEATS AND NOTES

This driver implements basic functionality and a couple of driver-specific attributes.
Starting with 0.20, DBI::Shell is (partially) supported.

=head2 $dbh->{ss_maxhitsinternalcolumns} (driver-specific database attribute)
This attribute modifies allocation of result values buffers. It is checked when an actual
allocation is made. So, use it as soon as possible and try to use it throughout an application.
Seting this attribute to a positive integer makes the driver allocate an additional
14 * ss_maxhitsinternalcolumns for any char-based column.
This is to allow for expansion of returned data length from internal columns
when SHOW_MATCHES includes 'INTERNAL_COLUMNS' (i.e. SET SHOW_MATCHES 'TRUE' or
SET SHOW_MATCHES 'INTERNAL_COLUMNS').
With these SHOW_MATCHES settings, SearchServer inserts match start/end markers in the
column data (when retrieving). If this attribute is not set it defaults to 0;
in which case the column will be truncated at its original length, so that part of
the original data will not be returned.
Truncation of data is not considered an error. To check if a truncation occurs you
can use $h->state checking a 01004 condition (as per the example in test.pl).
For compatibility with previous releases (named DBD::Fulcrum),
$dbh->{ful_maxhitsinternalcolumns} is recognized as an alias for this attribute.

=head2 $sth->{ss_last_row_id} (driver-specific statement attribute, read-only)
After an INSERT, UPDATE or DELETE statement, you can get the row id (FT_CID) of the last
affected row via $sth->{ss_last_row_id}.
If not after INSERT, UPDATE or DELETE the value of this attribute is unspecified.
Code contributed by Loic Dachary (see acknoledgments section).
Note that to use this attribute you must use prepare/execute instead of "do" since only
prepare will return a $sth, and only execute will initialize the attribute.
For compatibility with previous releases (named DBD::Fulcrum),
$sth->{ful_last_row_id} will be recognized as an alias for this attribute.

=head2 $sth->{CursorName} (DBI-standard statement attribute, read-only)
This driver supports the CursorName attribute via SQLGetCursorName.

=head2 Please be patient
I have not a lot of time to dedicate to this driver nowadays. If you find a problem,
and even better its solution, I will be very grateful if you let me know.

=head1 PLATFORM-SPECIFIC NOTES

=head2 Solaris
Reports have been in of problems running DBD::SearchServer under Solaris.
The problem usually manifests as a cryptic "relocation error" in ld.so.1.
You have this problem if a query succeeds using execsql but fails from a Perl program.
The solution (hopefully) is to set
	LD_PRELOAD=$FULCRUM_HOME/lib/libftft.so
in your environment.
Thanks to Juha Makinen (FI) who found the solution and relayed it to me.

=head2 Digital Unix

Very important instructions can be found in README.dec_osf.

=head2 Windows NT
Starting with version 0.12 you should be able to build under Microsoft(tm) Windows(tm) NT(tm).

Environment variables have very little usefulness there, BUT you'll need
FULCRUM_HOME set because Makefile.PL depends on it.
Instead of using FULSEARCH, use the first parameter to connect in order to
specify the ODBC data source (which roughly define a directory for SearchServer to use).
test.pl uses the definition of the environment variable DBI_DSN, read on.

So in order to build and test:

*please note* I have successfully built and tested with SearchServer 3.5c under NT 4.0,
Microsoft Visual C++ 5.0, perl 5.004_57 (of the development track) and DBI 0.92.
I can't imagine what could happen in another situation. And, I most definitely lack
the time to test. If you feel like it, try and let me know your configuration,
I'll add it to this file.

First of all, have SearchServer installed and running. Test your SearchServer before
trying to use DBI, please.
Declare a new ODBC data source that you'll need to use for the after-build test.
Let's name it "testdsn". Notice the FULCREATE, FULSEARCH and FULTEMP values?
Instead of using the environment, you define them here.
Copy to the directory you specified for FULCREATE and FULSEARCH (do yourself a
favour and let them be the same), the exactly same files you see in build-dir.sh
(THAT will not work, sorry) unless you don't see them in FULCRUM_HOME\fultext
(that is, ignore the ftpdf.ini file if it's missing). You'll at mininum need
fultext.ftc, and the *mess files.
Use execsql, select the just declared data source "testdsn", and run the test.fte
you find here. This will create the TEST table used by the tests
(I'm losing count of tests here :-).

In your worthy Command Prompt, set the environment variable DBI_DSN:
	set DBI_DSN=testdsn

Rememeber to set FULCRUM_HOME to the base installation directory of the SearchServer C SDK.

Now you should be able to perl Makefile.PL, nmake and nmake install. At least it worked for me.


=head1 COLLATERALS

PCDOCS/Fulcrum SearchServer: http://www.pcdocs.com


=head1 SEE ALSO

L<DBI>

=head1 AUTHOR

DBD::SearchServer by Davide Migliavacca.

=head1 ACKNOWLEDGEMENTS

All people working on DBI-related projects, and most specially Tim Bunce for
creating DBI itself.
Roberto Bianchettin <robertob@pisa.iol.it>, Juha Makinen, Peter Wyngaard for testing
unstable releases and finding problems (and solutions!)
Loic Dachary <loic@ceic.com> for adding support for retrienving FT_CID values
after insert, update or delete.
Peter Wyngaard <peterw@anecdote.com> for adding support to the CursorName attribute.
Ted Lemon, for continuing support to the dbi mailing lists.


=head1 COPYRIGHT

The DBD::SearchServer module is
Copyright (c) 1996,1997,1998,1999 Davide Migliavacca, Milano ITALY


You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

