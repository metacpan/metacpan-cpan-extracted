######################################################################
#
# Tests DB::Handy as a reusable CPAN component, covering patterns
# similar to HTTP::Handy (structured request/response log analysis)
# and LTSV::LINQ (record-oriented query chaining and aggregation).
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use DB::Handy;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok      { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is      { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub rows_ok { my($r,$c,$n)=@_; $T++; (ref($r) eq 'ARRAY')&&(@$r==$c) ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got=".(ref($r) eq 'ARRAY'?scalar@$r:'undef').", exp=$c)\n") }

print "1..99\n";
use File::Path ();

###############################################################################
# Setup
###############################################################################
my $BASE = "/tmp/dbd_first_cpan_$$";
File::Path::rmtree($BASE) if -d $BASE;
my $db = DB::Handy->new(base_dir => $BASE);

# ok 1
ok(defined $db, "new() returns object");

# ok 2
ok($db->execute("CREATE DATABASE api")->{type} eq 'ok', "CREATE DATABASE api");

# ok 3
ok($db->execute("USE api")->{type} eq 'ok', "USE api");

###############################################################################
# HTTP::Handy-style  --  structured request/response patterns
# DB::Handy models HTTP-like structured data: each row is a "request record"
# with status, method, path, latency.  Queries simulate log analysis.
###############################################################################
{
    $db->execute("CREATE TABLE http_log (
        id      INT,
        method  VARCHAR(8),
        path    VARCHAR(64),
        status  INT,
        latency INT,
        host    VARCHAR(32)
    )");

    my @rows = (
        "(1, 'GET',    '/index',    200, 12,  'host-a')",
        "(2, 'POST',   '/api/data', 201, 45,  'host-b')",
        "(3, 'GET',    '/index',    200, 8,   'host-a')",
        "(4, 'GET',    '/missing',  404, 5,   'host-c')",
        "(5, 'DELETE', '/api/data', 204, 30,  'host-b')",
        "(6, 'GET',    '/api/data', 200, 22,  'host-a')",
        "(7, 'POST',   '/index',    500, 120, 'host-c')",
        "(8, 'GET',    '/api/data', 200, 18,  'host-b')",
    );
    for my $row (@rows) {
        $db->execute("INSERT INTO http_log (id,method,path,status,latency,host) VALUES $row");
    }

    # Filter 2xx responses only
    my $r = $db->execute("SELECT id, method, path FROM http_log WHERE status >= 200 AND status < 300 ORDER BY id");

    # ok 4
    rows_ok($r->{data},, 6, "2xx responses: 6 rows");

    # ok 5
    is($r->{data}[0]{method}, 'GET',  "first 2xx is GET");

    # Average latency for GET requests
    $r = $db->execute("SELECT AVG(latency) AS avg_lat FROM http_log WHERE method = 'GET'");

    # ok 6
    ok($r->{type} eq 'rows', "AVG latency query OK");

    # ok 7
    ok($r->{data}[0]{avg_lat} > 0, "avg_lat > 0");

    # Count error responses (4xx, 5xx)
    $r = $db->execute("SELECT COUNT(*) AS errs FROM http_log WHERE status >= 400");

    # ok 8
    is($r->{data}[0]{errs}, 2, "error count = 2");

    # Request count per host
    $r = $db->execute("SELECT host, COUNT(*) AS cnt FROM http_log GROUP BY host ORDER BY host");

    # ok 9
    rows_ok($r->{data},, 3, "3 distinct hosts");
    my %hc = map { $_->{host} => $_->{cnt} } @{$r->{data}};

    # ok 10
    is($hc{'host-a'}, 3, "host-a: 3 requests");

    # ok 11
    is($hc{'host-b'}, 3, "host-b: 3 requests");

    # ok 12
    is($hc{'host-c'}, 2, "host-c: 2 requests");

    # Maximum latency per path
    $r = $db->execute("SELECT path, MAX(latency) AS max_lat FROM http_log GROUP BY path ORDER BY path");
    my %pl = map { $_->{path} => $_->{max_lat} } @{$r->{data}};

    # ok 13
    is($pl{'/index'},    120, "/index max_lat=120");

    # ok 14
    is($pl{'/api/data'}, 45,  "/api/data max_lat=45");

    # Top 3 slowest requests
    $r = $db->execute("SELECT id, latency FROM http_log ORDER BY latency DESC LIMIT 3");

    # ok 15
    rows_ok($r->{data},, 3, "LIMIT 3 slow requests");

    # ok 16
    is($r->{data}[0]{latency}, 120, "slowest latency=120");

    # Aggregate by status code
    $r = $db->execute("SELECT status, COUNT(*) AS cnt FROM http_log GROUP BY status ORDER BY status");
    my %sc = map { $_->{status} => $_->{cnt} } @{$r->{data}};

    # ok 17
    is($sc{200}, 4, "status 200: 4 rows");

    # ok 18
    is($sc{201}, 1, "status 201: 1 row");

    # ok 19
    is($sc{404}, 1, "status 404: 1 row");

    # ok 20
    is($sc{500}, 1, "status 500: 1 row");

    # HAVING: paths with average latency > 20ms
    $r = $db->execute("SELECT path, AVG(latency) AS avg_lat FROM http_log GROUP BY path HAVING AVG(latency) > 20 ORDER BY path");

    # ok 21
    ok($r->{type} eq 'rows', "HAVING AVG > 20 OK");
    my %ha = map { $_->{path} => 1 } @{$r->{data}};

    # ok 22
    ok(exists $ha{'/api/data'}, "/api/data has avg>20");

    # ok 23
    ok(exists $ha{'/index'},    "/index has avg>20");
}

###############################################################################
# LTSV::LINQ-style  --  record query chaining / projection
# LTSV (Labeled Tab-Separated Values) is a key:value log format.
# LINQ-style: SELECT (project), WHERE (filter), GROUP BY (aggregate),
#             ORDER BY (sort), LIMIT/OFFSET (paginate).
###############################################################################
{
    $db->execute("CREATE TABLE events (
        id       INT,
        category VARCHAR(16),
        label    VARCHAR(32),
        score    INT,
        flag     VARCHAR(4)
    )");

    my @ev = (
        "(1,  'click', 'btn-submit',  10, 'yes')",
        "(2,  'view',  'page-top',     3, 'no' )",
        "(3,  'click', 'btn-cancel',   5, 'yes')",
        "(4,  'view',  'page-detail',  7, 'yes')",
        "(5,  'click', 'btn-submit',  10, 'no' )",
        "(6,  'view',  'page-top',     3, 'yes')",
        "(7,  'event', 'load',         1, 'no' )",
        "(8,  'click', 'btn-submit',  10, 'yes')",
        "(9,  'event', 'unload',       2, 'yes')",
        "(10, 'view',  'page-detail',  7, 'no' )",
    );
    for my $ev (@ev) {
        $db->execute("INSERT INTO events (id,category,label,score,flag) VALUES $ev");
    }

    # SELECT (projection)
    my $r = $db->execute("SELECT id, label FROM events WHERE category = 'click' ORDER BY id");

    # ok 24
    rows_ok($r->{data},, 4, "click events: 4 rows");

    # ok 25
    ok(!exists $r->{data}[0]{score}, "projection: score not in result");

    # ok 26
    ok( exists $r->{data}[0]{label}, "projection: label in result");

    # WHERE chaining (AND + OR)
    $r = $db->execute("SELECT id FROM events WHERE (category = 'click' OR category = 'view') AND flag = 'yes' ORDER BY id");

    # ok 27
    rows_ok($r->{data},, 5, "click OR view, flag=yes: 5 rows");

    # ok 28
    is($r->{data}[0]{id}, 1, "first id=1");

    # GROUP BY + COUNT + SUM
    $r = $db->execute("SELECT category, COUNT(*) AS cnt, SUM(score) AS total FROM events GROUP BY category ORDER BY category");

    # ok 29
    rows_ok($r->{data},, 3, "3 categories");
    my %cat = map { $_->{category} => $_ } @{$r->{data}};

    # ok 30
    is($cat{click}{cnt},   4,  "click count=4");

    # ok 31
    is($cat{click}{total}, 35, "click sum=35");

    # ok 32
    is($cat{view}{cnt},    4,  "view count=4");

    # ok 33
    is($cat{event}{cnt},   2,  "event count=2");

    # DISTINCT projection
    $r = $db->execute("SELECT DISTINCT category FROM events ORDER BY category");

    # ok 34
    rows_ok($r->{data},, 3, "DISTINCT categories: 3");

    # LIMIT + OFFSET (pagination)
    $r = $db->execute("SELECT id FROM events ORDER BY id LIMIT 3 OFFSET 0");

    # ok 35
    rows_ok($r->{data},, 3, "page 1: 3 rows");

    # ok 36
    is($r->{data}[0]{id}, 1, "page1 first id=1");

    # ok 37
    is($r->{data}[2]{id}, 3, "page1 last id=3");

    $r = $db->execute("SELECT id FROM events ORDER BY id LIMIT 3 OFFSET 3");

    # ok 38
    rows_ok($r->{data},, 3, "page 2: 3 rows");

    # ok 39
    is($r->{data}[0]{id}, 4, "page2 first id=4");

    # BETWEEN filter
    $r = $db->execute("SELECT id FROM events WHERE score BETWEEN 5 AND 10 ORDER BY id");

    # ok 40
    rows_ok($r->{data},, 6, "score BETWEEN 5 AND 10: 6 rows");

    # LIKE filter
    $r = $db->execute("SELECT id FROM events WHERE label LIKE 'btn%' ORDER BY id");

    # ok 41
    rows_ok($r->{data},, 4, "label LIKE 'btn%': 4 rows");

    # ORDER BY multiple columns
    $r = $db->execute("SELECT category, score FROM events ORDER BY category ASC, score DESC LIMIT 4");

    # ok 42
    rows_ok($r->{data},, 4, "ORDER BY 2 cols: 4 rows");

    # ok 43
    is($r->{data}[0]{category}, 'click', "first category=click");

    # Column alias + expression
    $r = $db->execute("SELECT id, score * 2 AS double_score FROM events WHERE id <= 3 ORDER BY id");

    # ok 44
    rows_ok($r->{data},, 3, "expression alias: 3 rows");

    # ok 45
    is($r->{data}[0]{double_score}, 20, "id=1 double_score=20");

    # ok 46
    is($r->{data}[1]{double_score}, 6,  "id=2 double_score=6");

    # IS NULL / IS NOT NULL
    $db->execute("CREATE TABLE nullable (id INT, val VARCHAR(16))");
    $db->execute("INSERT INTO nullable (id, val) VALUES (1, 'hello')");
    $db->execute("INSERT INTO nullable (id, val) VALUES (2, '')");
    $db->execute("INSERT INTO nullable (id, val) VALUES (3, 'world')");

    $r = $db->execute("SELECT id FROM nullable WHERE val IS NOT NULL AND val != '' ORDER BY id");

    # ok 47
    rows_ok($r->{data},, 2, "IS NOT NULL and non-empty: 2 rows");

    # ok 48
    is($r->{data}[0]{id}, 1, "first non-null id=1");
}

###############################################################################
# Insert/Update/Delete lifecycle (CRUD API pattern)
###############################################################################
{
    $db->execute("CREATE TABLE items (id INT, name VARCHAR(32), qty INT, active VARCHAR(4))");

    for my $i (1..5) {
        $db->execute("INSERT INTO items (id,name,qty,active) VALUES ($i, 'item$i', " . ($i * 10) . ", 'yes')");
    }

    # Read
    my $r = $db->execute("SELECT COUNT(*) AS n FROM items");

    # ok 49
    is($r->{data}[0]{n}, 5, "initial count=5");

    # Update single row

    # ok 50
    ok($db->execute("UPDATE items SET qty = 99 WHERE id = 3")->{type} eq 'ok', "UPDATE single row");
    $r = $db->execute("SELECT qty FROM items WHERE id = 3");

    # ok 51
    is($r->{data}[0]{qty}, 99, "qty updated to 99");

    # Update with expression

    # ok 52
    ok($db->execute("UPDATE items SET qty = qty + 1 WHERE active = 'yes'")->{type} eq 'ok', "UPDATE with expression");
    $r = $db->execute("SELECT qty FROM items WHERE id = 1");

    # ok 53
    is($r->{data}[0]{qty}, 11, "id=1 qty = 10+1 = 11");

    # Delete with WHERE

    # ok 54
    ok($db->execute("DELETE FROM items WHERE qty > 90")->{type} eq 'ok', "DELETE WHERE qty>90");
    $r = $db->execute("SELECT COUNT(*) AS n FROM items");

    # ok 55
    is($r->{data}[0]{n}, 4, "after DELETE: 4 rows");

    # Upsert pattern: INSERT then UPDATE
    $db->execute("INSERT INTO items (id,name,qty,active) VALUES (10,'newitem',0,'no')");

    # ok 56
    ok($db->execute("UPDATE items SET qty = 50, active = 'yes' WHERE id = 10")->{type} eq 'ok', "upsert via UPDATE");
    $r = $db->execute("SELECT qty, active FROM items WHERE id = 10");

    # ok 57
    is($r->{data}[0]{qty},    50,    "upserted qty=50");

    # ok 58
    is($r->{data}[0]{active}, 'yes', "upserted active=yes");

    # Bulk delete

    # ok 59
    ok($db->execute("DELETE FROM items WHERE active = 'no'")->{type} eq 'ok', "DELETE inactive");
    $r = $db->execute("SELECT COUNT(*) AS n FROM items WHERE active = 'no'");

    # ok 60
    is($r->{data}[0]{n}, 0, "no inactive rows remain");
}

###############################################################################
# Relational queries with JOIN (ORM-style association)
###############################################################################
{
    $db->execute("CREATE TABLE users  (uid INT, uname VARCHAR(32), role VARCHAR(16))");
    $db->execute("CREATE TABLE orders (oid INT, uid INT, product VARCHAR(32), amount INT)");

    for my $row (
        "(1,'alice','admin')", "(2,'bob','user')", "(3,'carol','user')", "(4,'dave','guest')"
    ) { $db->execute("INSERT INTO users (uid,uname,role) VALUES $row") }

    for my $row (
        "(1,1,'Widget-A',100)", "(2,1,'Widget-B',200)", "(3,2,'Gadget-X',150)",
        "(4,3,'Widget-A',100)", "(5,3,'Gizmo-Z',300)",  "(6,2,'Gizmo-Z',300)",
    ) { $db->execute("INSERT INTO orders (oid,uid,product,amount) VALUES $row") }

    # INNER JOIN
    my $r = $db->execute("SELECT u.uname, o.product FROM users u INNER JOIN orders o ON u.uid = o.uid ORDER BY o.oid");

    # ok 61
    rows_ok($r->{data},, 6, "INNER JOIN: 6 order rows");

    # ok 62
    is($r->{data}[0]{'u.uname'}, 'alice', "first order: alice");

    # LEFT JOIN (dave has no orders)
    $r = $db->execute("SELECT u.uname, o.product FROM users u LEFT JOIN orders o ON u.uid = o.uid ORDER BY u.uid");

    # ok 63
    rows_ok($r->{data},, 7, "LEFT JOIN: 7 rows (4 users, dave+null)");

    # JOIN + GROUP BY: total order amount per user
    $r = $db->execute("SELECT u.uname, COUNT(*) AS cnt, SUM(o.amount) AS total FROM users u INNER JOIN orders o ON u.uid = o.uid GROUP BY u.uname ORDER BY u.uname");

    # ok 64
    rows_ok($r->{data},, 3, "JOIN+GROUP BY: 3 users with orders");
    my %ut = map { defined($_->{'u.uname'}) ? $_->{'u.uname'} : $_->{'uname'} => $_ } @{$r->{data}};

    # ok 65
    is($ut{alice}{cnt},   2,   "alice: 2 orders");

    # ok 66
    is($ut{alice}{total}, 300, "alice: total=300");

    # ok 67
    is($ut{carol}{total}, 400, "carol: total=400");

    # Subquery: find users who placed high-value orders
    $r = $db->execute("SELECT uname FROM users WHERE uid IN (SELECT uid FROM orders WHERE amount >= 300)");

    # ok 68
    ok($r->{type} eq 'rows', "subquery IN OK");
    my %names = map { $_->{uname} => 1 } @{$r->{data}};

    # ok 69
    ok(exists $names{carol}, "carol bought amount>=300");

    # ok 70
    ok(exists $names{bob},   "bob bought amount>=300");
}

###############################################################################
# Schema operations and metadata (framework introspection)
###############################################################################
{
    # list tables
    my @tables = $db->list_tables();

    # ok 71
    ok(scalar @tables >= 5, "list_tables: >= 5 tables");

    # ok 72
    ok(scalar(grep { $_ eq 'http_log' } @tables), "http_log listed");

    # ok 73
    ok(scalar(grep { $_ eq 'events'   } @tables), "events listed");

    # ok 74
    ok(scalar(grep { $_ eq 'users'    } @tables), "users listed");

    # table structure
    my $cols = $db->describe_table('orders');

    # ok 75
    ok(ref $cols eq 'ARRAY', "describe_table returns arrayref");
    my %cn = map { $_->{name} => $_->{type} } @$cols;

    # ok 76
    ok(exists $cn{oid},     "orders has oid column");

    # ok 77
    ok(exists $cn{uid},     "orders has uid column");

    # ok 78
    ok(exists $cn{product}, "orders has product column");

    # ok 79
    ok(exists $cn{amount},  "orders has amount column");

    # ok 80
    is($cn{oid},    'INT',     "oid type=INT");

    # ok 81
    is($cn{product},'VARCHAR', "product type=VARCHAR");

    # DROP TABLE

    # ok 82
    ok($db->execute("DROP TABLE nullable")->{type} eq 'ok', "DROP TABLE nullable");
    my @after = $db->list_tables();

    # ok 83
    ok(!scalar(grep { $_ eq 'nullable' } @after), "nullable removed from list");

    # list databases
    my @dbs = $db->list_databases();

    # ok 84
    ok(scalar(grep { $_ eq 'api' } @dbs), "api database listed");

    # case where errstr is set
    my $res = $db->execute("SELECT * FROM no_such_table");

    # ok 85
    ok($res->{type} eq 'error', "SELECT from missing table => error");

    # ok 86
    ok(defined $DB::Handy::errstr && $DB::Handy::errstr ne '', "errstr set on error");
}

###############################################################################
# CASE / COALESCE / string functions (functional/pipeline pattern)
###############################################################################
{
    $db->execute("CREATE TABLE products (pid INT, pname VARCHAR(32), price INT, stock INT)");
    my @prod = (
        "(1,'Alpha',  1000, 50)",
        "(2,'Beta',   2500, 0 )",
        "(3,'Gamma',   800, 10)",
        "(4,'Delta',  5000, 5 )",
        "(5,'Epsilon',1200, 0 )",
    );
    for my $p (@prod) {
        $db->execute("INSERT INTO products (pid,pname,price,stock) VALUES $p");
    }

    # CASE WHEN: stock status label
    my $r = $db->execute("SELECT pname, CASE WHEN stock = 0 THEN 'soldout' WHEN stock < 10 THEN 'low' ELSE 'ok' END AS status FROM products ORDER BY pid");

    # ok 87
    rows_ok($r->{data},, 5, "CASE WHEN: 5 rows");
    my %ps = map { $_->{pname} => $_->{status} } @{$r->{data}};

    # ok 88
    is($ps{Alpha},   'ok',      "Alpha stock=50 => ok");

    # ok 89
    is($ps{Beta},    'soldout', "Beta stock=0 => soldout");

    # ok 90
    is($ps{Delta},   'low',     "Delta stock=5 => low");

    # ok 91
    is($ps{Epsilon}, 'soldout', "Epsilon stock=0 => soldout");

    # String functions: UPPER / LENGTH / SUBSTR
    $r = $db->execute("SELECT UPPER(pname) AS up, LENGTH(pname) AS len FROM products WHERE pid = 1");

    # ok 92
    is($r->{data}[0]{up},  'ALPHA', "UPPER(Alpha)=ALPHA");

    # ok 93
    is($r->{data}[0]{len}, 5,       "LENGTH(Alpha)=5");

    # COALESCE for out-of-stock default display
    $r = $db->execute("SELECT pname, COALESCE(stock, 0) AS s FROM products WHERE pid = 2");

    # ok 94
    is($r->{data}[0]{s}, 0, "COALESCE(0,0)=0");

    # NOT IN filter
    $r = $db->execute("SELECT pid FROM products WHERE pid NOT IN (2, 5) ORDER BY pid");

    # ok 95
    rows_ok($r->{data},, 3, "NOT IN (2,5): 3 rows");

    # ok 96
    is($r->{data}[0]{pid}, 1, "first pid=1");

    # EXISTS subquery
    $r = $db->execute("SELECT uname FROM users WHERE EXISTS (SELECT oid FROM orders WHERE orders.uid = users.uid AND orders.amount >= 200) ORDER BY uname");

    # ok 97
    ok($r->{type} eq 'rows', "EXISTS subquery OK");
    my %en = map { $_->{uname} => 1 } @{$r->{data}};

    # ok 98
    ok(exists $en{alice}, "alice has order>=200");

    # ok 99
    ok(exists $en{carol}, "carol has order>=200");
}

###############################################################################
# Cleanup
###############################################################################
File::Path::rmtree($BASE) if -d $BASE;

exit($FAIL ? 1 : 0);
