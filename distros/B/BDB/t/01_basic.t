#! perl

$| = 1;

print "1..10\n";

use BDB;

BDB::max_parallel 1;

my $env = db_env_create;

print $env->set_flags (BDB::AUTO_COMMIT | BDB::TXN_NOSYNC, 1) ? "not " : "", "ok 1\n";

$env->set_flags      (&BDB::LOG_AUTOREMOVE  | &BDB::LOG_INMEMORY ) if BDB::VERSION v0, v4.7;
$env->log_set_config (&BDB::LOG_AUTO_REMOVE | &BDB::LOG_IN_MEMORY) if BDB::VERSION v4.7;

db_env_open
  $env,
  undef,
  BDB::PRIVATE
  | BDB::INIT_LOCK | BDB::INIT_LOG | BDB::INIT_MPOOL
  | BDB::INIT_TXN | BDB::RECOVER | BDB::USE_ENVIRON | BDB::CREATE,
  0600;

print $! ? "not " : "", "ok 2 # $!\n";#d#

my $db = db_create $env;

db_open $db, undef, undef, undef, BDB::BTREE, BDB::AUTO_COMMIT | BDB::CREATE, 0600;

print $! ? "not " : "", "ok 3 # $!\n";#d#

db_put $db, undef, "key", "data", sub {
   print "ok 5\n";
   db_del $db, undef, "key";
};
db_sync $db, sub {
   print "ok 6\n";
};
print "ok 4\n";
BDB::flush;

print "ok 7\n";
db_sync $db;
print "ok 8\n";

undef $db;
print "ok 9\n";
undef $env;
print "ok 10\n";


