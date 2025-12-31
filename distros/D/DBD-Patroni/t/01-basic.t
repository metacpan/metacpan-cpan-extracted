#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Test module loading
use_ok('DBD::Patroni');

# Test _parse_dsn function
my ( $clean_dsn, $params );

( $clean_dsn, $params ) =
  DBD::Patroni::_parse_dsn('dbname=test;patroni_url=http://host:8008/cluster');
is( $clean_dsn,                'dbname=test', 'DSN without patroni params' );
is( $params->{patroni_url},    'http://host:8008/cluster', 'patroni_url extracted' );

( $clean_dsn, $params ) = DBD::Patroni::_parse_dsn(
    'dbname=test;patroni_url=http://host:8008/cluster;patroni_lb=random');
is( $clean_dsn,             'dbname=test',              'DSN with multiple patroni params' );
is( $params->{patroni_url}, 'http://host:8008/cluster', 'patroni_url extracted (multi)' );
is( $params->{patroni_lb},  'random',                   'patroni_lb extracted' );

( $clean_dsn, $params ) = DBD::Patroni::_parse_dsn(
    'dbname=test;host=localhost;patroni_timeout=5;port=5432');
is( $clean_dsn, 'dbname=test;host=localhost;port=5432', 'DSN preserves non-patroni params' );
is( $params->{patroni_timeout}, '5', 'patroni_timeout extracted from middle' );

( $clean_dsn, $params ) = DBD::Patroni::_parse_dsn('dbname=test;host=localhost');
is( $clean_dsn,              'dbname=test;host=localhost', 'DSN unchanged without patroni params' );
is( scalar keys %$params,    0,                            'No patroni params extracted' );

( $clean_dsn, $params ) = DBD::Patroni::_parse_dsn(
    'patroni_url=http://a:8008/cluster,http://b:8008/cluster;dbname=test');
is( $clean_dsn,             'dbname=test',                             'DSN with comma-separated URLs' );
is( $params->{patroni_url}, 'http://a:8008/cluster,http://b:8008/cluster', 'comma-separated URLs preserved' );

# Test _build_dsn function
my $dsn;
$dsn = DBD::Patroni::_build_dsn( 'dbname=test', 'newhost', 5433 );
is( $dsn, 'dbname=test;host=newhost;port=5433', '_build_dsn adds host and port' );

$dsn = DBD::Patroni::_build_dsn( 'dbname=test;host=oldhost;port=5432', 'newhost', 5433 );
is( $dsn, 'dbname=test;host=newhost;port=5433', '_build_dsn replaces existing host/port' );

$dsn = DBD::Patroni::_build_dsn( 'host=oldhost;dbname=test;port=5432', 'newhost', 5433 );
is( $dsn, 'dbname=test;host=newhost;port=5433', '_build_dsn handles host/port at start' );

$dsn = DBD::Patroni::_build_dsn( 'dbname=test;;', 'newhost', 5433 );
is( $dsn, 'dbname=test;host=newhost;port=5433', '_build_dsn cleans up multiple semicolons' );

$dsn = DBD::Patroni::_build_dsn( ';dbname=test;', 'newhost', 5433 );
is( $dsn, 'dbname=test;host=newhost;port=5433', '_build_dsn cleans leading/trailing semicolons' );

# Test _is_readonly function
is( DBD::Patroni::_is_readonly('SELECT * FROM users'), 1,
    'SELECT is readonly' );
is( DBD::Patroni::_is_readonly('select id from users'),
    1, 'select (lowercase) is readonly' );
is( DBD::Patroni::_is_readonly('  SELECT * FROM users'),
    1, 'SELECT with leading space is readonly' );
is( DBD::Patroni::_is_readonly('WITH cte AS (SELECT 1) SELECT * FROM cte'),
    1, 'WITH...SELECT is readonly' );
is( DBD::Patroni::_is_readonly('INSERT INTO users (name) VALUES (?)'),
    0, 'INSERT is not readonly' );
is( DBD::Patroni::_is_readonly('UPDATE users SET name = ?'),
    0, 'UPDATE is not readonly' );
is( DBD::Patroni::_is_readonly('DELETE FROM users'),
    0, 'DELETE is not readonly' );
is( DBD::Patroni::_is_readonly('CREATE TABLE foo (id int)'),
    0, 'CREATE is not readonly' );
is( DBD::Patroni::_is_readonly('DROP TABLE foo'), 0, 'DROP is not readonly' );
is( DBD::Patroni::_is_readonly(undef),            0, 'undef is not readonly' );

# Test _select_replica function
my @replicas = (
    { host => 'replica1', port => 5432 },
    { host => 'replica2', port => 5432 },
    { host => 'replica3', port => 5432 },
);

# leader_only mode
is( DBD::Patroni::_select_replica( \@replicas, 'leader_only' ),
    undef, 'leader_only returns undef' );

# random mode (just check it returns something valid)
my $random = DBD::Patroni::_select_replica( \@replicas, 'random' );
ok( $random,                          'random mode returns a replica' );
ok( grep { $_ eq $random } @replicas, 'random returns one of the replicas' );

# empty replicas
is( DBD::Patroni::_select_replica( [], 'round_robin' ),
    undef, 'empty replicas returns undef' );
is( DBD::Patroni::_select_replica( undef, 'round_robin' ),
    undef, 'undef replicas returns undef' );

# round_robin mode
# Reset round-robin index for predictable testing
{ no warnings 'once'; $DBD::Patroni::rr_idx = 0; }
my $rr1 = DBD::Patroni::_select_replica( \@replicas, 'round_robin' );
my $rr2 = DBD::Patroni::_select_replica( \@replicas, 'round_robin' );
my $rr3 = DBD::Patroni::_select_replica( \@replicas, 'round_robin' );
my $rr4 = DBD::Patroni::_select_replica( \@replicas, 'round_robin' );

is( $rr1->{host}, 'replica1', 'round_robin first call returns replica1' );
is( $rr2->{host}, 'replica2', 'round_robin second call returns replica2' );
is( $rr3->{host}, 'replica3', 'round_robin third call returns replica3' );
is( $rr4->{host}, 'replica1', 'round_robin fourth call wraps to replica1' );

# Test _is_connection_error function
# Connection errors that should trigger rediscovery
is( DBD::Patroni::_is_connection_error('connection refused'),
    1, 'connection refused is connection error' );
is( DBD::Patroni::_is_connection_error('connection reset by peer'),
    1, 'connection reset is connection error' );
is( DBD::Patroni::_is_connection_error('could not connect to server'),
    1, 'could not connect is connection error' );
is(
    DBD::Patroni::_is_connection_error(
        'server closed the connection unexpectedly'),
    1,
    'server closed is connection error'
);
is( DBD::Patroni::_is_connection_error('no connection to the server'),
    1, 'no connection is connection error' );
is(
    DBD::Patroni::_is_connection_error(
        'terminating connection due to administrator command'),
    1,
    'terminating connection is connection error'
);
is( DBD::Patroni::_is_connection_error('connection timed out'),
    1, 'connection timed out is connection error' );
is( DBD::Patroni::_is_connection_error('lost connection to server'),
    1, 'lost connection is connection error' );

# Read-only errors (leader became replica after failover)
is(
    DBD::Patroni::_is_connection_error(
        'cannot execute INSERT in a read-only transaction'),
    1,
    'read-only INSERT is connection error'
);
is(
    DBD::Patroni::_is_connection_error(
        'cannot execute UPDATE in a read-only transaction'),
    1,
    'read-only UPDATE is connection error'
);
is(
    DBD::Patroni::_is_connection_error(
        'cannot execute DELETE in a read-only transaction'),
    1,
    'read-only DELETE is connection error'
);
is(
    DBD::Patroni::_is_connection_error(
        'ERROR: cannot execute TRUNCATE in a read-only transaction'),
    1,
    'read-only TRUNCATE is connection error'
);

# PostgreSQL recovery/startup errors (node not ready after failover)
is(
    DBD::Patroni::_is_connection_error(
        'FATAL: the database system is starting up'),
    1,
    'database starting up is connection error'
);
is(
    DBD::Patroni::_is_connection_error(
        'FATAL: the database system is in recovery mode'),
    1,
    'database in recovery mode is connection error'
);
is(
    DBD::Patroni::_is_connection_error(
        'FATAL: the database system is shutting down'),
    1,
    'database shutting down is connection error'
);
is( DBD::Patroni::_is_connection_error('recovery is in progress'),
    1, 'recovery in progress is connection error' );
is(
    DBD::Patroni::_is_connection_error(
        'FATAL: the database system is not accepting connections'),
    1,
    'not accepting connections is connection error'
);
is(
    DBD::Patroni::_is_connection_error(
        'FATAL: hot standby mode is disabled'),
    1,
    'hot standby disabled is connection error'
);

# SQL errors that should NOT trigger rediscovery
is( DBD::Patroni::_is_connection_error('syntax error at or near "SELEC"'),
    0, 'syntax error is not connection error' );
is(
    DBD::Patroni::_is_connection_error(
        'relation "nonexistent" does not exist'),
    0,
    'missing relation is not connection error'
);
is(
    DBD::Patroni::_is_connection_error('permission denied for table users'),
    0, 'permission denied is not connection error'
);
is(
    DBD::Patroni::_is_connection_error(
        'duplicate key value violates unique constraint'),
    0,
    'unique violation is not connection error'
);
is( DBD::Patroni::_is_connection_error(undef),
    0, 'undef is not connection error' );
is( DBD::Patroni::_is_connection_error(''),
    0, 'empty string is not connection error' );

done_testing();
