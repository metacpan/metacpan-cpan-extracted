use strict;
use lib ('./blib/lib','./blib/arch');

BEGIN {
    use Test::More;

    if (defined $ENV{DBI_DSN}) {
        require DBI;
        plan 'no_plan';
    } else {
        plan skip_all => 'cannot test pure_sql without DBI_DSN defined in environment';
    }
    use_ok('CGI::Session');
    use_ok('CGI::Session::Driver::pure_sql');
};


my $dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
            {RaiseError => 1, AutoCommit => 1});
ok(defined $dbh,'connect without transaction');

if ($dbh->{Driver}->{Name} eq 'Pg') {
    # Good, keep testing
}
else {
    plan skip_all => 'Only PostgreSQL is supported for testing now',
}


eval {
    $dbh->do("
    CREATE TABLE cgises_test (
        session_id       CHAR(32) NOT NULL
        , remote_addr        inet
        , creation_time      timestamp
        , last_access_time   timestamp
        , duration           interval
        , order_id           int
        , order_id_exp_secs  int
    )");
};
ok(!$@, 'created session table for testing');

#DBI->trace(1);

$ENV{REMOTE_ADDR} = '127.0.0.1';

# Test for default table name of 'sessions'
my $s;
eval { $s = CGI::Session->new('driver:pure_sql;serializer:sql_abstract',undef, {Handle=>$dbh}) };
ok (!$@, 'new() survives without TableName') or diag $@;

# warn 'class'.ref($s);

use Data::Dumper;
is($s->_driver->table_name, 'sessions', 'session table name defaults to sessions (in session object)')
    || diag Dumper($s);

# A warning will produced by the test about now. That's expected. -mls 10/27/03

eval { $s = undef; };

eval { $s = CGI::Session->new('driver:pure_sql;serializer:sql_abstract',undef, {Handle=>$dbh,TableName=>'cgises_test'}) };
ok (!$@, 'new() survives') or diag $@;

ok($s->id, 'fetch session ID');

$s->param(order_id => 127 );

is( $s->param('order_id'), 127, 'testing param identity');

ok(!$s->expire(), 'expecting expire to return undef when no expire date was set' );

$s->expire("+10m");


is($s->expire(), 600, "expire() expected to return time in seconds");

$s->expire('order_id'=>'+10m');

my $sid = $s->id();

# save creation time to compare it later.
my $ctime_from_first_session = $s->ctime;

#DBI->trace(2);
ok($s->close, 'closing 1st session');

my ($sid_in_db,$duration) = $dbh->selectrow_array("SELECT session_id,duration FROM cgises_test WHERE session_id = ?",{},$sid);

is( $sid_in_db, $sid, "found row for closed session 1. (sid was: $sid)");
my $s2;
eval { $s2 = CGI::Session->new('driver:pure_sql;serializer:sql_abstract',$sid, {Handle=>$dbh,TableName=>'cgises_test'}) };
is($@,'', 'survived eval');
ok($s2, 'created second test session');

# XXX re-using variable names
($sid_in_db,$duration) = $dbh->selectrow_array("SELECT session_id,duration FROM cgises_test WHERE session_id = ?",{},$sid);
is($sid_in_db,$sid, "found row for closed session 1 after creating second session. (sid was: $sid)");

# The REs groks newer and older PostgreSQL date formatting.
like($duration, qr/00:10(:00)?/, "expiration time is represented in the database.");

is($s2->id,$sid, 'checking session identity');

###
{
    my $test = 'setting expiration date in an UPDATE statement works';

    $s->expire("+20m");

    $s->flush;

    my ($duration) = $dbh->selectrow_array("SELECT duration FROM cgises_test WHERE session_id = ?",{},$sid);
    like($duration, qr/00:20(:00)?/, "expiration time is represented in the database.");
}

###


is($s2->param('order_id'),'127','checking ability to retrieve session data');

my $ctime_from_second_session = $s2->ctime;
is($ctime_from_first_session,$ctime_from_second_session, 'creation time remains the same');

eval { $s2->delete; };
ok(!$@, 'delete() survives');

eval { $s2->flush };
is($@, '', 'closing 2nd session');

END {
    ok ($dbh->do("DROP TABLE cgises_test"), 'dropping test table');
    ok($dbh->disconnect, 'disconnecting');
}

