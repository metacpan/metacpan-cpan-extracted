#
# Test the 'force application' function
#
# $Id: 50force.t,v 165.1 2009/04/22 14:06:39 biersma Exp $
#

#
# Get the database name from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $test_db = $myconfig{DBNAME};

use strict;
use Test::More tests => 10;
BEGIN { use_ok('DB2::Admin'); }

$| = 1;

my $rc = DB2::Admin->SetOptions('RaiseError' => 1);
ok ($rc, "SetOptions");

$rc = DB2::Admin->Attach();
ok ($rc, "Attach");

#
# In order to test the 'force application' function, we do the
# following:
#
# - Get a snapshot to determine active databases and pick one to
#   connect to.
# - Run a 'db2' command to connect
# - Inquire for active applications using a snapshot
# - Find our handle
# - Issue a force
# - Inquire again
# - Verify handle is gone
#
my $snap = DB2::Admin->GetSnapshot('Subject' => 'SQLMA_DBASE_ALL');
ok ($snap, "Database snapshot");

my $now = time();
if ($^O =~ /^MSWin/) {
    #
    # Force a delay to give the DB2 command time to connect
    #
    sleep(3);

    $rc = system("start db2cmd db2 connect to $test_db > /tmp/err 2>&1");
    ok($rc == 0, "Started DB2cmd to connect to $test_db");

    #
    # Force a delay to give the DB2 command time to connect
    #
    sleep(3);
} else {			# Unix
    $rc = system("db2 connect to $test_db > /tmp/err 2>&1");
    ok($rc == 0, "Connect to $test_db");
}

$snap = DB2::Admin->GetSnapshot('Subject' => 'SQLMA_APPL_ALL');
ok ($snap, "Application snapshot (before)");

my $agent_id;
my $username = ($^O =~ /^MSWin / ? $ENV{USERNAME} : getpwuid($<));
foreach my $node ($snap->findNodes('APPL')) {
    my $dbname = $node->findValue('APPL_INFO/DB_NAME');
    $dbname =~ s/\s+$//;
    next unless (lc $dbname eq lc $test_db);

    my $user = $node->findValue('APPL_INFO/EXECUTION_ID');
    next unless (lc($user) eq $username);
    my $conn_time = $node->findValue('APPL_CON_TIME/SECONDS');
    next unless ($conn_time >= $now);

    $agent_id = $node->findValue('APPL_INFO/AGENT_ID');
    last;
}

ok($agent_id, "Determine agent id ($agent_id)");

$rc = DB2::Admin::->ForceApplications($agent_id);
ok($rc, "Force Applications");

sleep(5);

$snap = DB2::Admin->GetSnapshot('Subject' => [ qw(SQLMA_DB2 SQLMA_APPL_ALL) ]);
ok ($snap, "Application snapshot (after)");

my $found = 0;
foreach my $node ($snap->findNodes('APPL')) {
    my $try = $node->findValue('APPL_INFO/AGENT_ID');
    if ($try == $agent_id) {
	$found = 1;
	last;
    }
}
ok($found == 0, "Agent id $agent_id no longer active");

