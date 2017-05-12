#!/usr/bin/env perl
#
# curref.pl          - by Geoffrey Young
#
# for this example, we create a package that contains
# two procedures:
#   emp_cursor       - returns a specific cursor reference
#   ref_cursor_close - closes any cursor reference
#
# to actually run this example as is, you will need the
# oracle demo tables.  otherwise, it's just sample code...

use DBI;
use DBD::Oracle qw(:ora_types);

use strict;

# Set trace level if '-# trace_level' option is given
DBI->trace( shift ) if 1 < @ARGV && $ARGV[0] =~ /^-#/ && shift;

die "syntax: $0 [-# trace] base user pass" if 3 > @ARGV;
my ( $inst, $user, $pass ) = @ARGV;

# Connect to database
my $dbh = DBI->connect( "dbi:Oracle:$inst", $user, $pass,
    { AutoCommit => 0, RaiseError => 1, PrintError => 0 } )
    or die $DBI::errstr;

my $sql = qq(
  CREATE OR REPLACE PACKAGE curref_test
  IS
    TYPE cursor_ref IS REF CURSOR;
    PROCEDURE emp_cursor (job_in  IN VARCHAR2, curref IN OUT cursor_ref);
    PROCEDURE ref_cursor_close (curref IN cursor_ref);
  END;
);
my $rv = $dbh->do($sql);
print "The package has been created...\n";

$sql = qq(
  CREATE OR REPLACE PACKAGE BODY curref_test
  IS 
    PROCEDURE emp_cursor (job_in IN VARCHAR2, curref IN OUT cursor_ref)
    IS
    BEGIN
      OPEN curref FOR select ename, job from emp where job = job_in;
    END;

    PROCEDURE ref_cursor_close (curref IN cursor_ref)
    IS
    BEGIN
      close curref;
    END;
  END;
);
$rv = $dbh->do($sql);
print "The package body has been created...\n";

print "These are the results from the ref cursor:\n";
$sql = qq(
   BEGIN
     curref_test.emp_cursor(:job_in, :curref);
   END;
);
my $curref;
my $sth = $dbh->prepare($sql);
$sth->bind_param(":job_in", "CLERK");
$sth->bind_param_inout(":curref", \$curref, 0, {ora_type => ORA_RSET});
$sth->execute;
$curref->dump_results;
open_cursors();

$sql = qq(
   BEGIN
     curref_test.ref_cursor_close(:curref);
   END;
);
$sth = $dbh->prepare($sql);
$sth->bind_param(":curref", $curref, {ora_type => ORA_RSET});
$sth->execute;

print "The cursor is now closed\n";
print "just to prove it...\n";
open_cursors();

$sql = "DROP PACKAGE curref_test"; # Also drops PACKAGE BODY
$rv = $dbh->do($sql);
print "The package has been dropped...\n";

$dbh->disconnect;

sub open_cursors {
  eval {
    $sth = $dbh->prepare(
      'SELECT user, sql_text FROM sys.v_$open_cursor ORDER BY user, sql_text');
    $sth->execute;
    print "Here are the open cursors:\n";
    $sth->dump_results;
  };
  if ( $@ ) {
      print "Unable to SELECT from SYS.V_\$OPEN_CURSOR:\n";
      if ( 942 == $DBI::err ) {
         print "   User $user needs SELECT permission.\n";
      }
      else { print "$@\n"; }
  }
}
