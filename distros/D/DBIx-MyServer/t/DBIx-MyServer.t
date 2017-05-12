# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBIx-MyServer.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use strict;

my $dbd_mysql_found = 0;
eval {
	require DBI;
	require DBD::mysql;
	$dbd_mysql_found = 1;
};

plan skip_all => "DBI or DBD::mysql not found($@)" if $dbd_mysql_found != 1;
plan tests => 3;
use_ok('DBIx::MyServer');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $pid;
my $port = 33306;
unless ($pid = fork()) {
    print "Spawning a MySQL test server on port $port, pid=$$...\n";
    exec("perl examples/myserver.pl --config=examples/test.conf --port=$port");
}

sleep 1;

my $dbh = DBI->connect("dbi:mysql:host=127.0.0.1:port=$port:user=myuser:password=myuser");
my $result = $dbh->selectrow_array("hello");
ok($result eq 'val1', 'myserver');
$dbh->disconnect();
kill(15,$pid);
ok(1,'done');
