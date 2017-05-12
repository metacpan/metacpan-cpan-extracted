#
# Test the snapshot functions
#
# $Id: 30snapshot.t,v 165.1 2009/02/24 14:47:26 biersma Exp $
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

#
# The DBASE_ALL snapshot requires a connection exist.  Create one.
#
if ($^O =~ /^MSWin/) {
    my $rc = system("start db2cmd db2 connect to $test_db > /tmp/err 2>&1");
    ok($rc == 0, "Started DB2cmd to connect to $test_db");

    #
    # Force a delay to give the DB2 command time to connect
    #
    sleep(5);
} else {                        # Unix
    my $rc = system("db2 connect to $test_db > /tmp/err 2>&1");
    ok($rc == 0, "Connect to $test_db");
}

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

my $retval = DB2::Admin->Attach();
ok($retval, "Attach");

$retval = DB2::Admin->GetSnapshot('Subject' => 'SQLMA_DBASE_ALL');
ok($retval, "Get database snapshot");

my $formatted = $retval->Format();
ok($formatted, "Format");

my ($node) = $retval->findNodes('DBASE/MEMORY_POOL');
ok($node, "findNodes");

$node = $retval->findNode('DBASE/MEMORY_POOL');
ok($node, "findNode");

my $rc = $node->findValue('POOL_ID');
ok (defined $rc, "findValue");

$rc = $node->getValues();
ok($rc, "getValues");
