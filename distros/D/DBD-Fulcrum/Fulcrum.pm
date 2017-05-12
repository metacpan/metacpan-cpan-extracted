#
#	Project		: DBD::Fulcrum
#	Module/Library	: 
#	Author		: $Author: shari $
#	Revision	: $Revision: 2.15 $
#	Check-in date	: $Date: 1998/12/16 14:46:33 $
#	Locked by	: $Locker:  $
#
#	----------------
#	Copyright	:
#	$Id: Fulcrum.pm,v 2.15 1998/12/16 14:46:33 shari Exp $ (c) 1996-98, Davide Migliavacca and Inferentia (Milano) IT
#	
#	Description	:

$DBD::Fulcrum::VERSION = '0.20';


{
    package DBD::Fulcrum;

    use DBI ();
    use DynaLoader ();
    use Exporter ();
    @ISA = qw(Exporter DynaLoader);
	
    my $Revision = substr(q$Revision: 2.15 $, 10);
    require_version DBI 1.00 ;

    bootstrap DBD::Fulcrum $VERSION;

    #use Fulcrum::Constants;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $state = "";	# DBI::state information

    $ful_maxhitsinternalcolumns = 0;
	# if you use SET SHOW_MATCHES 'TRUE' or 'INTERNAL_COLUMNS',
	# and don't like truncated columns, set this to > 0.
	# every internal column will have an additional 14 * $ful_maxhitsinternalcolumns bytes
        # in its buffer to allow for match start/end codes.
	# $h->state will report '01004' if a data truncation occurs (see test.pl)
    
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
			      'Name' => 'Fulcrum',
			      'Version' => $VERSION,
			      'Err'     => \$DBD::Fulcrum::err,
			      'Errstr'  => \$DBD::Fulcrum::errstr,
			      'State'   => \$DBD::Fulcrum::state,
			      'Attribution' => 'Fulcrum SearchServer DBD by Davide Migliavacca',
			     }
			    );

	$drh;
    }

    1;
}


{   package DBD::Fulcrum::dr; # ====== DRIVER ======
    use strict;

    sub connect {
	my($drh, $dbname, $user, $auth)= @_;

	if ($dbname){	# application is asking for specific database
	   # no use
	}

	# create a 'blank' dbh

	my $dbh = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'USER' => $user,
	    'CURRENT_USER' => $user,
	    });

	DBD::Fulcrum::db::_login($dbh, $dbname, $user, $auth)
	    or return undef;

	$dbh;
    }
    

}


{   package DBD::Fulcrum::db; # ====== DATABASE ======
    use strict;

    sub prepare {
	my($dbh, $statement,@attribs)= @_;

	# create a 'blank' dbh

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	DBD::Fulcrum::st::_prepare($sth, $statement,@attribs)
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


{   package DBD::Fulcrum::st; # ====== STATEMENT ======

    # all in XS

}

1;

__END__

=head1 NAME

DBD::Fulcrum - Fulcrum SearchServer database driver for the DBI module

=head1 SYNOPSIS

  use DBI;
  use DBD::Fulcrum;

  $ful_dbh = DBI->connect('dbi:Fulcrum:', $user, $passwd);
	# use $ENV{FULSEARCH} for "instance", $user and $pass normally empty


  # See the DBI module documentation for full details

=head1 DESCRIPTION

DBD::Fulcrum is a Perl module which works with the DBI module to provide
access to Fulcrum SearchServer data sources.

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

As a Fulcrum SearchServer SDK application, this driver will use the environment
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

=head2 DBD::Fulcrum::ful_maxhitsinternalcolumns (driver-specific attribute)
This attribute modifies allocation of result values buffers. It is driver-wide and is checked when an actual allocation is made. So, use it as soon as possible and try to use it throughout an application.
Seting this attribute to a positive integer makes the driver allocate an additional 14 * fulcrum_MaximumHistInInternalColumns bytes for any char-based column. This is to allow for expansion of returned data length from internal columns when SHOW_MATCHES includes 'INTERNAL_COLUMNS' (i.e. SET SHOW_MATCHES 'TRUE' or SET SHOW_MATCHES 'INTERNAL_COLUMNS').
With these SHOW_MATCHES settings, SearchServer inserts match start/end markers in the column data. If this attribute is not set it defaults to 0; in which case the column will be truncated at its original length, so that part of the original data will not be returned.
Truncation of data is not considered an error. To check if a truncation occurs you can use $h->state as per the example in test.pl.

=head2 $sth->{ful_last_row_id} (driver-specific read-only attribute)
After an INSERT, UPDATE or DELETE statement, you can get the row id (FT_CID) of the last
affected row via $sth->{ful_last_row_id}.
If not after INSERT, UPDATE or DELETE the value of this attribute is unspecified.
Code contributed by Loic Dachary (see acknoledgments section).
Note that to use this attribute you must use prepare/execute instead of "do" since only
prepare will return a $sth, and only execute will initialize the attribute.

=head2 $sth->{CursorName} (DBI-standard read-only attribute)
This driver supports the CursorName attribute via SQLGetCursorName.

=head2 Please be patient
I have not a lot of time to dedicate to this driver nowadays. If you find a problem, and even better its solution, I will be very grateful if you let me know.

=head1 PLATFORM-SPECIFIC NOTES

=head2 Solaris
Reports have been in of problems running DBD::Fulcrum under Solaris.
The problem usually manifests as a cryptic "relocation error" in ld.so.1.
You have this problem if a query succeeds using execsql but fails from a Perl program.
The solution (hopefully) is to set
	LD_PRELOAD=$FULCRUM_HOME/lib/libftft.so
in your environment.
Thanks to Juha Makinen (FI) who found the solution and relayed it to me.

=head2 Digital Unix
Due to the Fulcrum libraries being 32-bit, you'll have to build a static perl for DBD::Fulcrum to work on this platform.
Since I'm not a MakeMaker geek, you'll need to follow this ugly hack:
	1) perl Makefile.PL
	2) hand-edit Makefile.aperl
	3) change MAP_LINKCMD and change it to read $(CC) -taso plus whatever was there.
	4) make CB<-f> Makefile.aperl
(More or less). If you have a suggestion on how to streamline this with MakeMaker, please
let me know!
You'll get "unaligned access" console warnings due to 32-bitness of Fulcrum libraries.
Suppress the warnings using "uac", there's no other way to deal with this (that I know of).

=head2 Windows NT
Starting with version 0.12 you should be able to build under Microsoft(tm) Windows(tm) NT(tm).

Environment variables have very little usefulness there, BUT you'll need FULCRUM_HOME set because Makefile.PL depends on it.
Instead of using FULSEARCH, use the first parameter to connect in order to specify the ODBC data source (which roughly define a directory for SearchServer to use).
test.pl uses the definition of the environment variable DBI_DSN, read on.

So in order to build and test:

*please note* I have successfully built and tested with SearchServer 3.5c under NT 4.0, Microsoft Visual C++ 5.0, perl 5.004_57 (of the development track) and DBI 0.92. I can't imagine what could happen in another situation. And, I most definitely lack the time to test. If you feel like it, try and let me know your configuration, I'll add it to this file.

First of all, have SearchServer installed and running. Test your SearchServer before trying to use DBI, please.
Declare a new ODBC data source that you'll need to use for the after-build test. Let's name it "testdsn". Notice the FULCREATE, FULSEARCH and FULTEMP values? Instead of using the environment, you define them here.
Copy to the directory you specified for FULCREATE and FULSEARCH (do yourself a favour and let them be the same), the exactly same files you see in build-dir.sh (THAT will not work, sorry) unless you don't see them in FULCRUM_HOME\fultext (that is, ignore the ftpdf.ini file if it's missing). You'll at mininum need fultext.ftc, and the *mess files.
Use execsql, select the just declared data source "testdsn", and run the test.fte you find here. This will create the TEST table used by the tests (I'm losing count of tests here :-).

In your worthy Command Prompt, set the environment variable DBI_DSN:
	set DBI_DSN=testdsn

Rememeber to set FULCRUM_HOME to the base installation directory of the SearchServer C SDK.

Now you should be able to perl Makefile.PL, nmake and nmake install. At least it worked for me.



=head1 COLLATERALS

Fulcrum SearchServer: http://www.pcdocs.com


=head1 SEE ALSO

L<DBI>

=head1 AUTHOR

DBD::Fulcrum by Davide Migliavacca.

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

The DBD::Fulcrum module is
Copyright (c) 1996,1997,1998 Davide Migliavacca and Inferentia, Milano ITALY

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

