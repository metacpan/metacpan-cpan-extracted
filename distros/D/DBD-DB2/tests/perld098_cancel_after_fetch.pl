##############################################
# TESTCASE:        perld098_cancel_after_fetch.pl
# DESCRIPTION:     Execute, fetch one row, then $sth->cancel
# EXPECTED RESULT: Success; no further rows available after cancel
##############################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

my $testcase = $0;
$testcase =~ s@.*/@@;
my ($tcname, $extension) = split(/\./, $testcase);
my $success = 'y';

fvt_begin_testcase($tcname);

my $dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", { PrintError => 0 });
check_error('CONNECT');

my $sql = q{SELECT tabname, tabschema FROM syscat.tables FETCH FIRST 100 ROWS ONLY};
my $sth = $dbh->prepare($sql);
check_error('PREPARE');

$sth->execute();
check_error('EXECUTE');

# Fetch one row successfully
my $row1 = $sth->fetchrow_arrayref();
if (!defined $row1) {
    $success = 'n';
    warn 'expected at least one row before cancel, got none.';
}

# Now cancel the active statement
eval { $sth->cancel(); 1; } or do { $success = 'n'; warn "cancel() after fetch failed: $@"; };
check_error('CANCEL');

# Attempt another fetch after cancel — should not return a row
my $row2;
my $fetch_ok = eval { $row2 = $sth->fetchrow_arrayref(); 1; };
if ($fetch_ok && defined $row2) {
    $success = 'n';
    warn 'fetch after cancel returned a row—expected no data (closed cursor).';
}

$dbh->disconnect();
check_error('DISCONNECT');

fvt_end_testcase($testcase, $success);
