# Test fetching

use Test::More;
use DBI;
use strict;

if (defined $ENV{DBI_DSN}) {
    plan tests => 14;
}
else {
    plan skip_all => 'Cannot run test unless DBI_DSN is defined. See the README file.';
}

my $db = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                      {RaiseError => 1, PrintError => 0, AutoCommit => 1});

$db->do($_) for (
    'CREATE TEMPORARY TABLE threecol (a int, b int, c int)',
    'CREATE TEMPORARY TABLE fourcol  (a int, b int, c int, d int)',
    'CREATE TEMPORARY TABLE eightcol (
        a int, b int, c int, d int,
        e int, f int, g int, h int
     )',
    'INSERT INTO eightcol (a, b, c, d, e, f, g, h)
     SELECT       101, 102, 103, 104, 105, 106, 107, 108
     UNION SELECT 111, 112, 113, 114, 115, 116, 117, 118
     UNION SELECT 121, 122, 123, 124, 125, 126, 127, 128
     UNION SELECT 131, 132, 133, 134, 135, 136, 137, 138
     UNION SELECT 141, 142, 143, 144, 145, 146, 147, 148
     UNION SELECT 151, 152, 153, 154, 155, 156, 157, 158',

    'CREATE TEMPORARY TABLE t (id int primary key)',
    'INSERT INTO t (id)
     SELECT       1
     UNION SELECT 2
     UNION SELECT 3
     UNION SELECT 4
     UNION SELECT 5',
);

{
    # This set of tests is due to <worel@miit.ru>; see
    # http://rt.cpan.org/Public/Bug/Display.html?id=14318#txn-140623

    my $st = $db->prepare(q[
        SELECT id
        FROM t
        WHERE id < 5
        ORDER BY id
    ]);
    $st->execute;

    my @expected = map { +{ id => $_ } } 1 .. 4;
    while (my $row = $st->fetchrow_hashref) {
        my $expected = shift @expected;
        is_deeply($row, $expected, "Got correct result row $expected->{id}");
        ok($db->do(q[SELECT 1 AS one, 2 AS two]),
           "Nested query execution $expected->{id}");
    }
}

{
    # This set of tests is due to Roger Crew <crew@cs.stanford.edu>; see
    # http://rt.cpan.org/Public/Bug/Display.html?id=18733

    my $sel8 = $db->prepare(q[SELECT * FROM eightcol ORDER BY a]);
    $sel8->execute;
    is($sel8->{NUM_OF_FIELDS}, 8, 'Eight cols in result for eightcol');

    my $ins = $db->prepare(q[INSERT INTO threecol VALUES (?, ?, ?)]);
    is($ins->execute(10, 20, 30), 1, 'Insert affected 1 row');
    is($ins->{NUM_OF_FIELDS}, 0, 'No cols in result for threecol insert');

    my $sel4 = $db->prepare(q[SELECT * FROM fourcol]);
    $sel4->execute;
    is($sel4->{NUM_OF_FIELDS}, 4, 'Four cols in result for fourcol');

    my $inserted = eval { $ins->execute(11, 21, 31) };
    ok(!$@, 'No exception when inserting again');
    is($inserted, 1, 'Second insert affected 1 row');
}
