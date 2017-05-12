# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BBConfig.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('BoxBackup::Config::Accounts', 'BoxBackup::Config::DiskSets') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use BoxBackup::Config::Accounts;
$acc = BoxBackup::Config::Accounts->new("t/accounts.txt");
@acctIDs = $acc->getAccountIDs();

ok(defined($acc), 'defined');
ok($acc->isa('BoxBackup::Config::Accounts'), 'correct type');
ok($acc->getDisk(1) == 0, "Acct. 1 is on disk 0");
ok($#acctIDs == 10, "element count");

