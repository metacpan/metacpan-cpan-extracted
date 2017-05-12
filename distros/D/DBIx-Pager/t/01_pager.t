use strict;
use Test::More tests => 5;

use DBIx::Pager;
use DBI;

SKIP: {

    my $dbh;
    eval {
	$dbh = DBI->connect('dbi:SQLite:./t/test.db');
    };
    if ($@) {
	skip "DBD::SQLite is not installed", 5 unless $dbh;
    }

$dbh->do(<<'SQL');
CREATE TABLE test_tbl (
id INTEGER NOT NULL,
dat CHAR(32)
)
SQL

my $i = 1;
for my $dat(qw(foo bar baz)){
    my $sth = $dbh->prepare(<<"SQL");
INSERT INTO test_tbl (id, dat) VALUES(?, ?)
SQL
    $sth->execute($i, $dat);
    $sth->finish;
    $i++;
}

my $pager = DBIx::Pager->new(
    dbh => $dbh,
    table => 'test_tbl',
    limit => 2,
    offset => 0
);

ok($pager->has_next);
ok(!$pager->has_prev);
is($pager->next_offset, 2);
is($pager->current_page, 1);
is($pager->page_count, 2);

}

END {
    unlink 't/test.db';
}
