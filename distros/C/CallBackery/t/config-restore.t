use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackery::Config;
use CallBackeryTest qw(setupTestConfig);
use DBI;

# getConfigBlob shells out to sqlite3 to dump the database
plan skip_all => 'no /usr/bin/sqlite3' unless -x '/usr/bin/sqlite3';

# a config of our own so we do not share the config database with the other
# tests -- this one gets overwritten half way through
my $cfgDb = setupTestConfig()->{cfgDb};

my $t = Test::Mojo->new('CallBackery');
my $cfg = $t->app->config;
my $db  = $t->app->database;

is $cfg->cfgHash->{BACKEND}{cfg_db}, $cfgDb, 'the app uses our temporary config database';

$db->setConfigValue('restoreProbe','before');
my $blob = $cfg->getConfigBlob('secret');
$db->setConfigValue('restoreProbe','after');
is $db->getConfigValue('restoreProbe'),'after','probe value changed after taking the blob';

# a long lived handle, as held by the config daemon, its workers and by
# transient helpers such as a post start configuration script
my $live = DBI->connect("dbi:SQLite:dbname=$cfgDb",'','',{
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
});
is $live->selectrow_array('SELECT cbconfig_value FROM cbconfig WHERE cbconfig_id = ?',undef,'restoreProbe'),
    'after','the live handle sees the current value';

my $inodeBefore = (stat $cfgDb)[1];

$cfg->restoreConfigBlob($blob,'secret');

is +(stat $cfgDb)[1], $inodeBefore, 'the restore keeps the config database inode';

is $live->selectrow_array('SELECT cbconfig_value FROM cbconfig WHERE cbconfig_id = ?',undef,'restoreProbe'),
    'before','the live handle reads the restored data';

# the actual regression: with the database replaced rather than restored in
# place, SQLite fails this with SQLITE_READONLY_DBMOVED, reported as
# "attempt to write a readonly database"
ok eval {
    $live->do('INSERT INTO cbconfig (cbconfig_id,cbconfig_value) VALUES (?,?)',
        undef,'restoreWrite','ok');
    1;
}, 'the live handle can still write' or diag $@;

# A restore that cannot get the write lock must leave the database exactly as
# it was. Giving up is fine, half restoring is not.
{
    local $CallBackery::Config::RESTORE_BUSY_TIMEOUT_MS = 500;

    $db->setConfigValue('restoreProbe','busy');
    my $inode = (stat $cfgDb)[1];

    my $reader = DBI->connect("dbi:SQLite:dbname=$cfgDb",'','',{
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
    });
    $reader->begin_work;
    $reader->selectrow_array('SELECT count(*) FROM cbconfig');

    ok !eval { $cfg->restoreConfigBlob($blob,'secret'); 1 },
        'a restore blocked by another connection fails';
    like "$@",qr/restore the configuration database/,
        'and fails with the restore error, not something incidental';

    is +(stat $cfgDb)[1], $inode, 'the blocked restore left the inode alone';
    is $db->getConfigValue('restoreProbe'),'busy',
        'the blocked restore left the data alone';

    $reader->rollback;
    $reader->disconnect;

    # and the database is still usable afterwards
    $db->setConfigValue('restoreProbe','afterBusy');
    is $db->getConfigValue('restoreProbe'),'afterBusy',
        'the database is still writable after a blocked restore';
}

# no staging database is left behind
is_deeply [glob "$cfgDb.restore*"],[],'the restore leaves no staging database behind';

$live->disconnect;

done_testing();
