use DBIx::SimpleQuery;
use Test::More tests => 20;

SKIP: {
    eval {
	require "DBD::SQLite";
    };

    skip "DBD::SQLite is required for these tests", 20 if $@;

    if (-r "simplequery_test.db") {
	diag "simplequery_test.db exists.  Removing.";
	unlink "simplequery_test.db";
    }

    DBIx::SimpleQuery::set_defaults("dsn" => "DBI:SQLite:simplequery_test.db",
				    "user" => "",
				    "password" => "");

# Object Type
    my $sql = new DBIx::SimpleQuery;
    is(ref($sql),
       "DBIx::SimpleQuery",
       "Correct object type");

    my $result = query("SELECT 2");

    is(ref($result),
       "",
       "ref(query('SELECT 2')) should be blank");

    $result = query ("SELECT 2 AS a, 4 AS b");

    is(ref($result),
       "DBIx::SimpleQuery::Object",
       "Check to ensure that a DBIx::SimpleQuery::Object is returned for a multi-column query");

    is($result->{"count"},
       1,
       "Row count accuracy check");

    is($result->{"field_count"},
       2,
       "Column count accuracy check");

    my $row <<= $result;

    is(ref($row),
       "HASH",
       "Check that <<= returns a HASH");

    ok(grep { $_ eq "a" } keys %{$row},
       "Test row has key a");

    ok(grep { $_ eq "b" } keys %{$row},
       "Test row has key b");

    is($row->{"a"},
       2,
       "Row a value check");

    is($row->{"b"},
       4,
       "Row b value check");

# Temporarily redirect stderr, since the query is most likely
# going to complain about an authentication failure.
    open OLDERR, ">&STDERR"   or die "cannot dup STDERR: $!";
    open STDERR, ">/dev/null"   or die "cannot dup STDERR: $!";
    select STDERR; $| = 1;

    eval {
	query("SELECT * FROM test_table");
    };

    ok($@,
       "Selecting from non-existent table should die");

# Restore STDERR.
    close STDERR;
    open STDERR, ">&OLDERR" or die "cannot dup OLDERR: $!";
    close OLDERR;

    query("CREATE TABLE test_table (x TEXT, y TEXT)");

    $@ = '';
    eval {
	query("SELECT * FROM test_table");
    };
    ok(!$@,
       "Selecting from existent table should *not* die");

    ok(!query("SELECT * FROM test_table"),
       "Boolean select on empty table should be false");

    query("INSERT INTO test_table VALUES ('a', 'b')");
    query("INSERT INTO test_table VALUES ('c', 'd')");
    query("INSERT INTO test_table VALUES ('e', 'f')");

    $result = query("SELECT * FROM test_table ORDER BY x");

    is("$result",
       3,
       "Stringification of multi-column query should be the row-count");

    my $first_row <<= $result;
    is($first_row->{"x"},
       "a",
       "<<= check");

    my $last_row >>= $result;
    is($last_row->{"x"},
       "e",
       ">>= check");

    my $i = 0;
    foreach my $j (1..$result) {
	$i++;
    }
    is($i,
       3,
       "1.. test");

    is(scalar @{$result},
       3,
       "Return-as-arrayref test");

    $i = 0;
    while (<$result>) {
	$i++;
    }
    is($i,
       3,
       "<> test");

    is(join("", query("SELECT x FROM test_table ORDER BY x")),
       "ace",
       "Return-as-array test");

    unlink "simplequery_test.db";

}
