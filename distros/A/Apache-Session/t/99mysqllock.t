use Test::More;

#plan skip_all => "Not running RDBM tests without APACHE_SESSION_MAINTAINER=1"
#  unless $ENV{APACHE_SESSION_MAINTAINER};
plan skip_all => "Optional modules (Test::Database, DBD::mysql, DBI) not installed"
  unless eval {
               require Test::Database;
               require DBD::mysql;
               require DBI;
              };

if ($ENV{TRAVIS}) {
    my $cfg = << 'EOT';
    driver_dsn  = dbi:mysql:
    username    = root
EOT
    Test::Database->load_config(\$cfg);
}

my @db_handles = Test::Database->handles('mysql');

plan skip_all => "No mysql handle reported by Test::Database"
  unless @db_handles;

my $mysql = $db_handles[0];
my $dsn = $mysql->dsn();
my $uname = $mysql->username();
my $upass = $mysql->password();

my $dbh  = DBI->connect($dsn, $uname, $upass);
plan skip_all => "Cannot connect to DB specified in Test::Database config"
  unless $dbh;

plan tests => 4;

my $package = 'Apache::Session::Lock::MySQL';
use_ok $package;

my $session = {
    args => {
        LockDataSource => $dsn,
        LockUserName   => $uname,
        LockPassword   => $upass,
    },
    data => {
        _session_id => '09876543210987654321098765432109',
    }
};

my $lock = $package->new;
my $sth  = $dbh->prepare(q{SELECT GET_LOCK('Apache-Session-09876543210987654321098765432109', 0)});
my $sth2 = $dbh->prepare(q{SELECT RELEASE_LOCK('Apache-Session-09876543210987654321098765432109')});

$lock->acquire_write_lock($session);

$sth->execute();
is +($sth->fetchrow_array)[0], 0, 'could not get lock';

$lock->release_write_lock($session);

$sth->execute();
is +($sth->fetchrow_array)[0], 1, 'could get lock';

$sth2->execute;
undef $lock;

$session->{args}->{LockHandle} = $dbh;

$lock = $package->new;

$lock->acquire_read_lock($session);

$sth->execute();
$sth->execute();
is +($sth->fetchrow_array)[0], 1, 'could get lock';

undef $lock;

$sth->finish;
$sth2->finish;
$dbh->disconnect;
