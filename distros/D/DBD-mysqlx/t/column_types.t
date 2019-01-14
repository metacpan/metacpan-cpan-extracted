use strict;
use warnings;
use DBI;
use DBD::mysqlx;
use Test::More tests => 17;
use utf8;

my $dsn = "DBI:mysqlx:localhost/test";
my $dbh = DBI->connect($dsn, "msandbox", "msandbox");
ok $dbh->do(<<'CREATE_TABLE'
CREATE TEMPORARY TABLE t1(
  id int PRIMARY KEY,
  c1 VARCHAR(255),
  c2 int,
  c3 json,
  c4 set('a','b'),
  c5 datetime,
  c6 timestamp,
  c7 timestamp(6),
  c8 double,
  c9 float,
  c10 time
)
CREATE_TABLE
);

ok $dbh->do(<<'INSERT_INTO'
INSERT INTO
t1(id, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10)
VALUES
(1, 'test', 1, '{"a": 5}', 'a', '2018-12-01 15:00:00', '2018-12-01 15:00:00',
 '2018-12-01 15:00:00.123456', 1/3, 1/3, "11:12:13"),
(2, 'test☺', -1, '{"a": null}', 'a,b', '2018-12-01 15:00:00', '2018-12-01 15:00:00',
 '2018-12-01 15:00:00.123456', 1/3, 1/3, "-11:12:13")
INSERT_INTO
);
ok my $sth = $dbh->prepare("SELECT * FROM t1 ORDER BY id");
ok $sth->execute();
ok my $row = $sth->fetchrow_hashref();
is $row->{'c1'}, "test", "basic string";
is $row->{'c2'}, 1, "positive integer";
is $row->{'c3'}, "{\"a\": 5}", "simple JSON";
is $row->{'c4'}, 'a', "one item of set";
# is $row->{'c5'}, '2018-12-01 15:00:00', "datetime";
# is $row->{'c6'}, '2018-12-01 15:00:00', "timestamp";
# is $row->{'c7'}, '2018-12-01 15:00:00.123456', "timestamp high precision";
is $row->{'c8'}, '0.333333333', "double";
# is $row->{'c9'}, '0.3333', "float";
# is $row->{'c10'}, '11:12:13', "positive time";

ok $row = $sth->fetchrow_hashref();
is $row->{'c1'}, "test☺", "smily string";
is $row->{'c2'}, -1, "negative integer";
is $row->{'c3'}, "{\"a\": null}", "JSON with null";
is $row->{'c4'}, 'a,b', "two item of set";
# is $row->{'c5'}, '2018-12-01 15:00:00', "datetime";
# is $row->{'c6'}, '2018-12-01 15:00:00', "timestamp";
# is $row->{'c7'}, '2018-12-01 15:00:00.123456', "timestamp high precision";
is $row->{'c8'}, '0.333333333', "double";
# is $row->{'c9'}, '0.3333', "float";
# is $row->{'c10'}, '-11:12:13', "negative time";

ok $sth->finish();

$dbh->disconnect();
