##############################################
# TESTCASE:        perld097_cancel_noexec.pl
# DESCRIPTION:     Call $sth->cancel without execute (prepared only)
# EXPECTED RESULT: Success (no error; idempotent behavior)
##############################################

use DBI;
use DBD::DB2;

require 'connection.pl';   # provides $DATABASE, $USERID, $PASSWORD
require 'perldutl.pl';     # provides fvt_begin_testcase, check_error, fvt_end_testcase

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";

fvt_begin_testcase($tcname);

my $dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", { PrintError => 0 });
check_error('CONNECT');

my $sql = q{SELECT tabname FROM syscat.tables FETCH FIRST 1 ROW ONLY};
my $sth = $dbh->prepare($sql);
check_error('PREPARE');

# Cancel without execute — should not error
eval {
    $sth->cancel();
    1;
} or do {
    $success = 'n';
    warn "cancel() (no execute) threw an exception: $@";
};
check_error('CANCEL');

# Optional: calling cancel again should also be harmless (idempotent)
eval { $sth->cancel(); 1; } or do { $success = 'n'; warn "second cancel() failed: $@"; };

$dbh->disconnect();
check_error('DISCONNECT');

fvt_end_testcase($testcase, $success);
