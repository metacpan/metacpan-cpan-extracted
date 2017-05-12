#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Cwd qw( getcwd );
use DBI qw(:sql_types);

unless (exists $ENV{DBPATH} && -d $ENV{DBPATH} && -r "$ENV{DBPATH}/file.db") {
    warn "\$DBPATH not set";
    print "1..0\n";
    exit 0;
    }
my $dbname = "DBI:Unify:$ENV{DBPATH}";

{   no warnings 'uninitialized';
    local $ENV{UNIFY} = undef;
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "Undefined \$UNIFY");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "Undef \$Unify error message");
    }

{   local $ENV{UNIFY} = "";
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "Empty \$UNIFY");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "Empty \$Unify error message");
    }

{   local $ENV{UNIFY} = "/dev/null";
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "\$UNIFY = /dev/null");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "\$Unify error message");
    }

{   local $ENV{UNIFY} = getcwd;
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "\$UNIFY = $ENV{UNIFY}");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "\$Unify error message");
    }

{   local $ENV{UNIFY} = __FILE__;
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "\$UNIFY = $ENV{UNIFY}");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "\$Unify error message");
    }

{   local $ENV{UNIFY} = getcwd;
    mkdir "bogus-dir", 0666;
    $ENV{UNIFY} .= "/bogus-dir";
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    rmdir $ENV{UNIFY};
    is ($dbh, undef, "\$UNIFY = $ENV{UNIFY}");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "\$Unify error message");
    }

{   delete $ENV{UNIFY};
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "No \$UNIFY");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "No \$Unify error message");
    }

# Known as bug 108243: segfault on subsequent connect when $UNIFY is not present
# See docs below
{   local $SIG{__WARN__} = sub {};
    SKIP: {
	skip "because UNIFY needs to correct bug 108243", 1;
	delete $ENV{UNIFY};
	my $dbh = DBI->connect ("dbi:Unify:", "", "DBUTIL", {
	    RaiseError => 0, PrintError => 0 });
	is ($dbh, undef, "Connect with \$UNIFY removed from ENV");
	}
    }

done_testing;

__END__

=head1 UNIFY BUG 108243: segfault on subsequent connect when $UNIFY is not present

Segfault when trying to connect a second time after a successful connect
when the $UNIFY variable has been removed from the environment.  Code example:

Known to be present in Dataserver 9.0G on RedHat 4.x/5.x ES i386

 #include <unistd.h>
 #include <stdlib.h>
 #include <stdio.h>
 #include <ctype.h>
 #include <string.h>

 #include <sqle_usr.h>
 #include <dbtypes.h>
 #include <fdesc.h>
 #include <rhli.h>
 #include <rhlierr.h>

 char *ufchmsg (USTATUS errnum, USTATUS *status);

 USTATUS SQLCODE;

 int main (int argc, char *argv[])
 {

    EXEC SQL BEGIN DECLARE SECTION;
    EXEC SQL END   DECLARE SECTION;

    USTATUS ustatus;

    EXEC SQL CONNECT;
    (void)printf ("1st connect, SQLCODE = %d\n", SQLCODE);
    if (SQLCODE) (void)printf ("%s\n", ufchmsg (SQLCODE, &ustatus));

    EXEC SQL DISCONNECT;
    (void)printf ("1st disconnect, SQLCODE = %d\n", SQLCODE);
    if (SQLCODE) (void)printf ("%s\n", ufchmsg( SQLCODE, &ustatus));

    /* now, remove the UNIFY variable */
    if (unsetenv ("UNIFY")) perror ("unsetenv");

    /* will segfault within CONNECT:
	typical (gdb) backtrace
	#0  0x080b091f in mkcffnm ()
	#1  0x080ea325 in bldcnf ()
	#2  0x080b00bb in uinicnf ()
	#3  0x080b0322 in iniconf ()
	#4  0x08050263 in feini ()
	#5  0x0804a3b5 in crsini ()
	#6  0x0804c203 in sqlopdb ()
	#7  0x0804a1b7 in main ()
       it will not segfault if you remove the "unsetenv" call above.
       it will also not segfault if you do not define UNIFY in the environment
         before you start this program (in that case you get SQLCODE = -16 on
	  each CONNECT)
     */
    EXEC SQL CONNECT;
    (void)printf ("2nd connect, SQLCODE = %d\n", SQLCODE);
    if (SQLCODE) (void)printf ("%s\n", ufchmsg (SQLCODE, &ustatus));

    EXEC SQL DISCONNECT;
    (void)printf ("2nd disconnect, SQLCODE = %d\n", SQLCODE );
    if (SQLCODE) (void)printf ("%s\n", ufchmsg (SQLCODE, &ustatus));
    } /* main */
