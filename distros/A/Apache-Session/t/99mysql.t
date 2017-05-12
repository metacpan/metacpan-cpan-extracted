use Test::More;
use Test::Deep;

#plan skip_all => "Not running RDBM tests without APACHE_SESSION_MAINTAINER=1"
#  unless ($ENV{APACHE_SESSION_MAINTAINER} || $ENV{TRAVIS});
plan skip_all => "Optional modules (Test::Database, DBD::mysql, DBI) not installed"
  unless eval {
               require Test::Database;
               require DBD::mysql;
               require DBI;
              };

my $dbd_mysq_ver = DBD::mysql->VERSION();
plan skip_all => "Version $dbd_mysq_ver of DBD::mysql has serious problems on Windows"
  if ($^O eq 'MSWin32' && $dbd_mysq_ver >= '4.021' && $dbd_mysq_ver <= '4.023');

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
diag "DBD::mysql version ".DBD::mysql->VERSION();

plan skip_all => "Test::Database handle->driver is undef. Probably it was not possible to establish connection."
  if !defined($mysql->driver);

diag "Mysql version ".$mysql->driver->version;

plan tests => 23;

my $package = 'Apache::Session::MySQL';
use_ok $package;

my @tables_used = qw/sessions s/;
sub drop_tables {
    my $dbh = shift;
    my $dblist = join(', ', @_);
    my $res = $dbh->do("DROP TABLE IF EXISTS $dblist");
    if (!defined $res and $dbh->errstr =~ /Cannot delete or update a parent row: a foreign key constraint/) {
      my $ary_ref = $dbh->selectcol_arrayref('SHOW TABLES');
      $dblist = join(', ', @$ary_ref);
      diag "Found foreign key constraint, trying to drop all tables from DB";
      
      $dbh->do("SET foreign_key_checks = 0");
      $dbh->do("DROP TABLE IF EXISTS $dblist");
      $dbh->do("SET foreign_key_checks = 1");
    }
}

{
    my $dbh1 = $mysql->dbh();
    drop_tables($dbh1, @tables_used);
    foreach my $table (@tables_used) {
        $dbh1->do(<<"EOT");
  CREATE TABLE $table (
    id char(32) not null primary key,
    a_session blob
  );
EOT
    }
}

my $session = {};

tie %{$session}, $package, undef, {
    DataSource     => $dsn,
    UserName       => $uname,
    Password       => $upass,
    LockDataSource => $dsn,
    LockUserName   => $uname,
    LockPassword   => $upass,
};

ok tied(%{$session}), 'session tied';

ok exists($session->{_session_id}), 'session id exists';

my $id = $session->{_session_id};

my $foo = $session->{foo} = 'bar';
my $baz = $session->{baz} = ['tom', 'dick', 'harry'];
my $test_value = $session->{'test'} = 12; #test for RT#50896

untie %{$session};
undef $session;
$session = {};

tie %{$session}, $package, $id, {
    DataSource     => $dsn,
    UserName       => $uname,
    Password       => $upass,
    LockDataSource => $dsn,
    LockUserName   => $uname,
    LockPassword   => $upass,
};

ok tied(%{$session}), 'session tied';

is $session->{_session_id}, $id, 'id retrieved matches one stored';

cmp_deeply $session->{foo}, $foo, "Foo matches";
cmp_deeply $session->{baz}, $baz, "Baz matches";
cmp_deeply $session->{test}, $test_value, "test matches";

untie %{$session};
undef $session;
$session = {};

{

tie %{$session}, $package, undef, {
    TableName      => 's',
    DataSource     => $dsn,
    UserName       => $uname,
    Password       => $upass,
    LockDataSource => $dsn,
    LockUserName   => $uname,
    LockPassword   => $upass,
};

ok tied(%{$session}), 'session tied';

ok exists($session->{_session_id}), 'session id exists';
my $id1 = $session->{_session_id};

$session{'test'} = 13;

untie %{$session};
undef $session;
$session = {};

tie %{$session}, $package, $id1, {
    TableName      => 's',
    DataSource     => $dsn,
    UserName       => $uname,
    Password       => $upass,
    LockDataSource => $dsn,
    LockUserName   => $uname,
    LockPassword   => $upass,
};

ok tied(%{$session}), 'session tied';

ok exists($session->{_session_id}), 'session id exists';

is($session->{_session_id}, $id1, 'session id is correct');
is($session{'test'}, 13, 'correct value retrieved');

untie %{$session};
undef $session;
$session = {};

tie %{$session}, $package, $id1, { #test for RT#50896
    TableName      => 's',
    DataSource     => $dsn,
    UserName       => $uname,
    Password       => $upass,
    LockDataSource => $dsn,
    LockUserName   => $uname,
    LockPassword   => $upass,
};

ok tied(%{$session}), 'session tied';

ok exists($session->{_session_id}), 'session id exists';

is($session->{_session_id}, $id1, 'session id is correct');
is($session{'test'}, 13, 'correct value retrieved');

}


untie %{$session};
undef $session;
$session = {};

my $dbh = DBI->connect($dsn, $uname, $upass, {RaiseError => 1});

tie %{$session}, $package, $id, {
    Handle     => $dbh,
    LockHandle => $dbh,
};

ok tied(%{$session}), 'session tied';

is $session->{_session_id}, $id, 'id retrieved matches one stored';

cmp_deeply $session->{foo}, $foo, "Foo matches";
cmp_deeply $session->{baz}, $baz, "Baz matches";
cmp_deeply $session->{'test'}, $test_value, "test matches";

tied(%{$session})->delete;
untie %{$session};
$dbh->disconnect;

unless ($ENV{TRAVIS}) {
    my $dbh1 = $mysql->dbh();
    drop_tables($dbh1, @tables_used);
}

