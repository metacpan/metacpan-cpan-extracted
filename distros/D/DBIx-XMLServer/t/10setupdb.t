# -*- Perl -*-
use Test::More tests => 7;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 6
	unless $db;

  my $dbh = open_db();

  $dbh->do('DROP TABLE dbixtest1');
  $dbh->do('DROP TABLE dbixtest2');

  ok($dbh->do(<<EOF), "Create table 1") or diag $dbh->errstr;
CREATE TABLE dbixtest1
(
  id INT UNSIGNED NOT NULL,
  name TEXT,
  manager INT UNSIGNED,
  dept INT UNSIGNED,
  birthday DATE NOT NULL,
  lastseen DATETIME,
  login VARCHAR(10)
)
EOF

  my $sth;
  eval {
    $sth = $dbh->prepare('INSERT INTO dbixtest1 VALUES (?,?,?,?,?,?,?)')
      or die $dbh->errstr;
    foreach my $record (split /\r?\n/, <<EOF) {
1,John Smith,NULL,1,1936-02-10,2004-09-30 17:30:00,john
2,Fred Bloggs,3,1,1963-01-01,NULL,fred
3,Ann Other,1,1,1955-05-10,2004-09-30 17:25:52,ann
4,Minnie Mouse,NULL,2,1976-02-28,2004-10-01 12:00:00,NULL
5,Mickey Mouse,4,2,1976-02-29,2004-10-01 12:00:01,mickey
EOF
      $sth->execute(map($_ eq 'NULL' ? undef : $_, split(/,/, $record)))
	or die $dbh->errstr;
    }
  };
  ok(!$@, "Populate table 1") or diag $@;

  ok($dbh->do(<<EOF), "Create table 2") or diag $dbh->errstr;
CREATE TABLE dbixtest2
(
  id INT UNSIGNED NOT NULL,
  name TEXT
)
EOF

  eval {
    $sth = $dbh->prepare('INSERT INTO dbixtest2 VALUES (?,?)')
      or die $dbh->errstr;
    foreach my $record (split /\r?\n/, <<EOF) {
1,Widget Manufacturing
2,Widget Marketing
EOF
      $sth->execute(map($_ eq 'NULL' ? undef : $_, split(/,/, $record)))
	or die $dbh->errstr;
    }
  };
  ok(!$@, "Populate table 2") or diag $@;

  close_db();
}
