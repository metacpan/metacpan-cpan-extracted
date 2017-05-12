# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BBConfig.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('BoxBackup::Config::Accounts', 'BoxBackup::Config::DiskSets') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use BoxBackup::Config::DiskSets;
$dsk = BoxBackup::Config::DiskSets->new("t/raidfile.conf");
@diskNames = $dsk->getListofDisks();

ok(defined($dsk), 'defined');
ok($dsk->isa('BoxBackup::Config::DiskSets'), 'correct type');
ok($dsk->getParamVal("disc0", "SetNumber") == 0, "SetNumber");
ok($dsk->getParamVal("disc0", "BlockSize") == 4096, "BlockSize");
ok($dsk->getParamVal("disc0", "Dir0") eq "/backup001.0", "Dir0");
ok($dsk->getParamVal("disc0", "Dir1") eq "/backup001.1", "Dir1");
ok($dsk->getParamVal("disc0", "Dir2") eq "/backup001.2", "Dir2");
ok($#diskNames == 1, "element count");

