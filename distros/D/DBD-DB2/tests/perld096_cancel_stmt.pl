##############################################
# TESTCASE:        perld096_cancel_stmt.pl
# DESCRIPTION:     Validate $sth->cancel closes an active statement
# EXPECTED RESULT: Success
##############################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";

fvt_begin_testcase($tcname);

# 1) Connect (same style as sample)
my $dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", { PrintError => 0 });
check_error('CONNECT');

# 2) Prepare a query that yields rows
my $sql = q{SELECT tabname, tabschema FROM syscat.tables FETCH FIRST 100 ROWS ONLY};
my $sth = $dbh->prepare($sql);
check_error('PREPARE');

# 3) Execute the statement (it becomes ACTIVE)
$sth->execute();
check_error('EXECUTE');

# 4) CANCEL the active statement (should close the cursor)
eval {
    $sth->cancel();
    1;
} or do {
    $success = 'n';
    warn "cancel() threw an exception: $@";
};
check_error('CANCEL');

# 5) Attempt to fetch after cancel — should not return a row
my $row;
my $fetch_ok = eval { $row = $sth->fetchrow_arrayref(); 1; };
if ($fetch_ok && defined $row) {
    $success = 'n';
    warn 'fetch succeeded after cancel—statement should be closed.';
}

# 6) Disconnect and finish
$dbh->disconnect();
check_error('DISCONNECT');

fvt_end_testcase($testcase, $success);