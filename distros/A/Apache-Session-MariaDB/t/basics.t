# ported from t/99mysql.t in Apache-Session

use Test::More;
use Test::Deep;

plan skip_all => "Set APACHE_SESSION_MARIADB_TEST to run this test"
    unless $ENV{APACHE_SESSION_MARIADB_TEST};


my $hostname = $ENV{APACHE_SESSION_MARIADB_TEST_HOST};
my $port     = $ENV{APACHE_SESSION_MARIADB_TEST_PORT};
my $dsn      = "DBI:MariaDB:database=$ENV{APACHE_SESSION_MARIADB_TEST}";
$dsn .= ";host=$ENV{APACHE_SESSION_MARIADB_TEST_HOST}" if $ENV{APACHE_SESSION_MARIADB_TEST_HOST};
$dsn .= ";port=$ENV{APACHE_SESSION_MARIADB_TEST_PORT}" if $ENV{APACHE_SESSION_MARIADB_TEST_PORT};

my $uname = $ENV{APACHE_SESSION_MARIADB_TEST_USER} || 'root';
my $upass = $ENV{APACHE_SESSION_MARIADB_TEST_PASS} || '';

use DBI;
my $dbh = DBI->connect( $dsn, $uname, $upass, { RaiseError => 1 } );

my $package = 'Apache::Session::MariaDB';
use_ok $package;

my @tables_used = qw/sessions s/;

sub drop_tables {
    my $dbh    = shift;
    my $dblist = join( ', ', @_ );
    my $res    = $dbh->do("DROP TABLE IF EXISTS $dblist");
    if ( !defined $res and $dbh->errstr =~ /Cannot delete or update a parent row: a foreign key constraint/ ) {
        my $ary_ref = $dbh->selectcol_arrayref('SHOW TABLES');
        $dblist = join( ', ', @$ary_ref );
        diag "Found foreign key constraint, trying to drop all tables from DB";

        $dbh->do("SET foreign_key_checks = 0");
        $dbh->do("DROP TABLE IF EXISTS $dblist");
        $dbh->do("SET foreign_key_checks = 1");
    }
}

{
    drop_tables( $dbh, @tables_used );
    foreach my $table (@tables_used) {
        $dbh->do(<<"EOT");
  CREATE TABLE $table (
    id char(32) not null primary key,
    a_session blob
  );
EOT
    }
}

my $session = {};

tie %{$session}, $package, undef,
    {
        DataSource     => $dsn,
        UserName       => $uname,
        Password       => $upass,
        LockDataSource => $dsn,
        LockUserName   => $uname,
        LockPassword   => $upass,
    };

ok tied( %{$session} ), 'session tied';

ok exists( $session->{_session_id} ), 'session id exists';

my $id = $session->{_session_id};

my $foo        = $session->{foo}    = 'bar';
my $baz        = $session->{baz}    = [ 'tom', 'dick', 'harry' ];
my $test_value = $session->{'test'} = 12;                           #test for RT#50896

untie %{$session};
undef $session;
$session = {};

tie %{$session}, $package, $id,
    {
        DataSource     => $dsn,
        UserName       => $uname,
        Password       => $upass,
        LockDataSource => $dsn,
        LockUserName   => $uname,
        LockPassword   => $upass,
    };

ok tied( %{$session} ), 'session tied';

is $session->{_session_id}, $id, 'id retrieved matches one stored';

cmp_deeply $session->{foo},  $foo,        "Foo matches";
cmp_deeply $session->{baz},  $baz,        "Baz matches";
cmp_deeply $session->{test}, $test_value, "test matches";

untie %{$session};
undef $session;
$session = {};

{

    tie %{$session}, $package, undef,
        {
            TableName      => 's',
            DataSource     => $dsn,
            UserName       => $uname,
            Password       => $upass,
            LockDataSource => $dsn,
            LockUserName   => $uname,
            LockPassword   => $upass,
        };

    ok tied( %{$session} ), 'session tied';

    ok exists( $session->{_session_id} ), 'session id exists';
    my $id1 = $session->{_session_id};

    $session{'test'} = 13;

    untie %{$session};
    undef $session;
    $session = {};

    tie %{$session}, $package, $id1,
        {
            TableName      => 's',
            DataSource     => $dsn,
            UserName       => $uname,
            Password       => $upass,
            LockDataSource => $dsn,
            LockUserName   => $uname,
            LockPassword   => $upass,
        };

    ok tied( %{$session} ), 'session tied';

    ok exists( $session->{_session_id} ), 'session id exists';

    is( $session->{_session_id}, $id1, 'session id is correct' );
    is( $session{'test'},        13,   'correct value retrieved' );

    untie %{$session};
    undef $session;
    $session = {};

    tie %{$session}, $package, $id1, {    #test for RT#50896
        TableName      => 's',
        DataSource     => $dsn,
        UserName       => $uname,
        Password       => $upass,
        LockDataSource => $dsn,
        LockUserName   => $uname,
        LockPassword   => $upass,
    };

    ok tied( %{$session} ), 'session tied';

    ok exists( $session->{_session_id} ), 'session id exists';

    is( $session->{_session_id}, $id1, 'session id is correct' );
    is( $session{'test'},        13,   'correct value retrieved' );

}


untie %{$session};
undef $session;
$session = {};

my $dbh = DBI->connect( $dsn, $uname, $upass, { RaiseError => 1 } );

tie %{$session}, $package, $id,
    {
        Handle     => $dbh,
        LockHandle => $dbh,
    };

ok tied( %{$session} ), 'session tied';

is $session->{_session_id}, $id, 'id retrieved matches one stored';

cmp_deeply $session->{foo},    $foo,        "Foo matches";
cmp_deeply $session->{baz},    $baz,        "Baz matches";
cmp_deeply $session->{'test'}, $test_value, "test matches";

tied( %{$session} )->delete;
untie %{$session};
$dbh->disconnect;

done_testing;
