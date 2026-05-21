use Test::More;
use JSON qw/from_json encode_json/;
use utf8;

our $test_dburl = $ENV{REDIS_URL}   || 'localhost:6379';
our $test_dbnum = $ENV{REDIS_DBNUM} || 15;
our $r;    # Redis handle used for asserts

plan skip_all => "Optional modules (Redis) not installed"
  unless eval { require Redis; };

plan skip_all => "Redis error : $@"
  unless eval {
    $r = Redis->new( server => $test_dburl );
    $r->select($test_dbnum);
    $r->flushall();
  };

plan tests => 57;

$package = 'Apache::Session::Browseable::Redis';

use_ok($package);

my $args = {
    server   => $test_dburl,
    database => $test_dbnum,

    # Choose your browseable fileds
    Index => 'uid sn mail int2',
};

use Data::Dumper;
my $id;
my $json;

is( keys %{ $r->keys('*') }, 0, "Make sure database is empty" );

# Create new session
my %session;
tie %session, $package, $id, $args;
$session{uid}   = 'mé';
$session{mail}  = 'mé@me.com';
$session{color} = 'zz';
$id             = $session{_session_id};
untie %session;

# Make sure it was stored:
ok( $r->exists($id),      "Test if new session id exists as a key in Redis" );
ok( $r->exists("uid_mé"), "Test if index exists" );
ok( $json = from_json( $r->get($id) ), "Parse redis value as JSON" );
is( $json->{mail}, 'mé@me.com', "Test if session subkey was correctly stored" );

# Read existing session
tie %session, $package, $id, $args;
is( $session{mail}, 'mé@me.com', "Test if session subkey can be read" );

# Delete session;
tied(%session)->delete;

ok( !$r->exists($id),      "Test if new session id was removed" );
ok( !$r->exists("uid_mé"), "Test if index was removed" );

is( keys %{ $r->keys('*') }, 0, "Make sure database is empty after removal" );
untie %session;

# Create a bunch of sessions to search on
my (
    %session1, %session2, %session3, %session4, %session5,
    $id1,      $id2,      $id3,      $id4,      $id5
);

tie %session1, $package, undef, $args;
$session1{uid}   = 'obiwan';
$session1{sn}    = 'Kenobi';
$session1{color} = 'blue';
$session1{int1}  = 10;
$session1{int2}  = 20;
$id1             = $session1{_session_id};
untie %session1;

tie %session2, $package, undef, $args;
$session2{uid}   = 'darthvader';
$session2{sn}    = 'Skywalker';
$session2{color} = 'red';
$session2{int1}  = 11;
$session2{int2}  = 21;
$id2             = $session2{_session_id};
untie %session2;

tie %session3, $package, undef, $args;
$session3{uid}   = 'luke';
$session3{sn}    = 'Skywalker';
$session3{color} = 'green';
$session3{int1}  = 12;
$session3{int2}  = 24;
$id3             = $session3{_session_id};
untie %session3;

tie %session4, $package, undef, $args;
$session4{uid}   = 'mace';
$session4{sn}    = 'Windu';
$session4{color} = 'purple';
$session4{int1}  = 13;
$session4{int2}  = 23;
$id4             = $session4{_session_id};
untie %session4;

tie %session5, $package, undef, $args;
$session5{uid}   = 'yoda';
$session5{sn}    = 'Yoda';
$session5{color} = 'green';
$session5{int1}  = 14;
$session5{int2}  = 22;
$id5             = $session5{_session_id};
untie %session5;

# Pollutes Redis
my $redis = 'Apache::Session::Browseable::Store::Redis'->_getRedis($args);
$redis->set( 'aaaa',     'bbbb' );
$redis->set( '@aaaa:aa', 'bbbb/bb' );

# Search all keys

my $hash = $package->get_key_from_all_sessions( $args, "uid" );

is( keys %$hash, 5, "Found all 5 session" );
ok( exists( $hash->{$id4} ), "Found 'mace' in result" );
is( $hash->{$id4}->{uid}, 'mace', "Correct value in session 4" );
ok( !defined( $hash->{$id4}->{sn} ), 'only uid is returned' );

$hash = $package->get_key_from_all_sessions($args);

is( keys %$hash, 5, "Found all 5 session" );
ok( exists( $hash->{$id4} ), "Found 'mace' in result" );
is( $hash->{$id4}->{uid}, 'mace',  "Correct value in session 4" );
is( $hash->{$id4}->{sn},  'Windu', 'All fields are returned' );

# Search on indexed field
$hash = $package->searchOn( $args, 'sn', 'Skywalker' );
is( keys %$hash,          2,            "Found 2 session" );
is( $hash->{$id2}->{uid}, 'darthvader', "Correct value" );
is( $hash->{$id3}->{uid}, 'luke',       "Correct value" );

$hash = $package->searchOnExpr( $args, 'sn', '*walker' );
is( keys %$hash,          2,            "Found 2 session" );
is( $hash->{$id2}->{uid}, 'darthvader', "Correct value" );
is( $hash->{$id3}->{uid}, 'luke',       "Correct value" );

# Search on unindexed field
$hash = $package->searchOn( $args, 'color', 'green' );
is( keys %$hash,          2,      "Found 2 session" );
is( $hash->{$id3}->{uid}, 'luke', "Correct value" );
is( $hash->{$id5}->{uid}, 'yoda', "Correct value" );

$hash = $package->searchOnExpr( $args, 'color', '*ee*', 'uid' );
is( keys %$hash,          2,      "Found 2 session" );
is( $hash->{$id3}->{uid}, 'luke', "Correct value" );
is( $hash->{$id5}->{uid}, 'yoda', "Correct value" );
ok( !defined( $hash->{$id3}->{sn} ), 'only uid is returned' );

# Test that updating an indexed field cleans up the old index
tie %session1, $package, $id1, $args;
ok( $r->sismember( "uid_obiwan", $id1 ),
    "Before update: id1 is in uid_obiwan index" );
$session1{uid} = 'benkenobi';
untie %session1;

ok( !$r->sismember( "uid_obiwan", $id1 ),
    "After update: id1 removed from old uid_obiwan index" );
ok( $r->sismember( "uid_benkenobi", $id1 ),
    "After update: id1 added to new uid_benkenobi index" );

# Verify searchOn uses the updated index
$hash = $package->searchOn( $args, 'uid', 'obiwan' );
is( keys %$hash, 0, "searchOn old value returns nothing" );

$hash = $package->searchOn( $args, 'uid', 'benkenobi' );
is( keys %$hash,            1,          "searchOn new value returns 1" );
is( $hash->{$id1}->{uid}, 'benkenobi', "Correct updated value" );

# Restore original value for subsequent tests
tie %session1, $package, $id1, $args;
$session1{uid} = 'obiwan';
untie %session1;

# Test that setting an indexed field to empty removes the index entry
tie %session1, $package, $id1, $args;
$session1{sn} = 'Kenobi';
untie %session1;

ok( $r->sismember( "sn_Kenobi", $id1 ), "sn_Kenobi index contains id1" );

tie %session1, $package, $id1, $args;
$session1{sn} = '';
untie %session1;

ok( !$r->sismember( "sn_Kenobi", $id1 ),
    "After clearing sn, old index entry removed" );

# Restore for deleteIfLowerThan test
tie %session1, $package, $id1, $args;
$session1{sn} = 'Kenobi';
untie %session1;

# Test deleteIfLowerThan cleans up indexes
$package->deleteIfLowerThan(
    $args,
    {
        or => {
            int1 => 12,
            int2 => 23,
        },
        not => {
            uid => 'yoda',
        }
    }
);

$hash = $package->get_key_from_all_sessions($args);
is( keys %$hash, 3, "Found 3 sessions after deleteIfLowerThan" );

# Verify that deleted sessions were removed from indexes
ok( !$r->sismember( "uid_obiwan", $id1 ),
    "deleteIfLowerThan cleaned uid index for deleted session" );
ok( !$r->sismember( "sn_Kenobi", $id1 ),
    "deleteIfLowerThan cleaned sn index for deleted session" );
ok( !$r->sismember( "uid_darthvader", $id2 ),
    "deleteIfLowerThan cleaned uid index for session 2" );
ok( $r->sismember( "uid_luke", $id3 ),
    "Surviving session still in uid index" );
ok( $r->sismember( "uid_yoda", $id5 ),
    "Excluded session (yoda) still in uid index" );

# Test that deleteIfLowerThan purges sessions missing required fields
# Create a session with no _utime (simulates an empty/interrupted session)
my %session_empty;
tie %session_empty, $package, undef, $args;
my $id_empty = $session_empty{_session_id};
$session_empty{uid} = 'ghost';
untie %session_empty;

# Remove _utime manually to simulate a bare session
my $raw_empty = $r->get($id_empty);
my $data_empty = from_json($raw_empty);
delete $data_empty->{_utime};
$r->set($id_empty, JSON::encode_json($data_empty));

$hash = $package->get_key_from_all_sessions($args);
ok( exists $hash->{$id_empty}, "Empty session exists before purge" );

$package->deleteIfLowerThan(
    $args,
    {
        or => { _utime => time },
    }
);

$hash = $package->get_key_from_all_sessions($args);
ok( !exists $hash->{$id_empty},
    "Session without _utime purged by deleteIfLowerThan" );
ok( !$r->sismember( "uid_ghost", $id_empty ),
    "Index cleaned for purged empty session" );

# Test lazy cleanup of orphan index entries in searchOn/searchOnExpr
$r->flushall;

my %session_lz1;
tie %session_lz1, $package, undef, $args;
$session_lz1{uid}  = 'alive';
$session_lz1{mail} = 'alive@test.com';
my $id_lz1 = $session_lz1{_session_id};
untie %session_lz1;

my %session_lz2;
tie %session_lz2, $package, undef, $args;
$session_lz2{uid}  = 'alive';
$session_lz2{mail} = 'dead@test.com';
my $id_lz2 = $session_lz2{_session_id};
untie %session_lz2;

# Both should be in uid_alive index
ok( $r->sismember( "uid_alive", $id_lz1 ), "Session lz1 in uid_alive index" );
ok( $r->sismember( "uid_alive", $id_lz2 ), "Session lz2 in uid_alive index" );

# Delete lz2 directly from Redis (simulates TTL expiration)
$r->del($id_lz2);

# searchOn should return only lz1 and clean orphan lz2 from index
$hash = $package->searchOn( $args, 'uid', 'alive' );
is( keys %$hash, 1, "searchOn returns only the surviving session" );
ok( exists $hash->{$id_lz1}, "searchOn returns lz1" );
ok( !$r->sismember( "uid_alive", $id_lz2 ),
    "searchOn lazy cleanup removed orphan lz2 from index" );
ok( $r->sismember( "uid_alive", $id_lz1 ),
    "searchOn kept valid lz1 in index" );

# Test lazy cleanup in searchOnExpr
my %session_lz3;
tie %session_lz3, $package, undef, $args;
$session_lz3{uid}  = 'expr_test';
$session_lz3{mail} = 'expr@test.com';
my $id_lz3 = $session_lz3{_session_id};
untie %session_lz3;

ok( $r->sismember( "uid_expr_test", $id_lz3 ), "Session lz3 in uid_expr_test index" );

# Delete lz3 directly (simulates TTL expiration)
$r->del($id_lz3);

# searchOnExpr should clean orphan
$hash = $package->searchOnExpr( $args, 'uid', 'expr_*' );
is( keys %$hash, 0, "searchOnExpr returns nothing for expired session" );
ok( !$r->sismember( "uid_expr_test", $id_lz3 ),
    "searchOnExpr lazy cleanup removed orphan lz3 from index" );

$r->flushall;
