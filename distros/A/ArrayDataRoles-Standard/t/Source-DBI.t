#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use DBI;
use File::Temp qw(tempfile);
use ArrayData::DBI;

my ($tempfh, $tempfile) = tempfile();
my $dbh = DBI->connect("dbi:SQLite:dbname=$tempfile", undef, undef, {RaiseError=>1});
$dbh->do("CREATE TABLE t (i INT PRIMARY KEY, t TEXT)");
$dbh->do("INSERT INTO t VALUES (1, 'one')");
$dbh->do("INSERT INTO t VALUES (2, 'two')");
$dbh->do("INSERT INTO t VALUES (3, 'three')");

# XXX test accept dsn, user, password instead of dbh
# XXX test accept sth & row_count_sth
# XXX test accept dbh, query, row_count_query

my $t = ArrayData::DBI->new(dbh=>$dbh, table=>'t', column=>'t');

$t->reset_iterator;
is_deeply($t->get_elem, 'one');
is_deeply($t->get_elem, 'two');
$t->reset_iterator;
is_deeply($t->get_elem, 'one');
is($t->get_elem_count, 3);

done_testing;
