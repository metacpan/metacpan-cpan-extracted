# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Daemon-Simple.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN {
use_ok('Daemon::Simple');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

Daemon::Simple::create_pidfile("./test.pid");
ok(-e"./test.pid",'check create_pidfile()');
ok(Daemon::Simple::get_pidfile("./test.pid") eq $$,'check pid');

Daemon::Simple::destroy_pidfile("./test.pid");
ok(!-e"./test.pid",'check destroy_pidfile()');

$SIG{'CHLD'} = 'IGNORE';
if($cid = fork())
{
ok(Daemon::Simple::is_running($cid),"check running process");
Daemon::Simple::kill_process($cid);
sleep(2);
ok(!Daemon::Simple::is_running($cid),"check process killed");
}
else
{
	while(1){ sleep 5; }
}

