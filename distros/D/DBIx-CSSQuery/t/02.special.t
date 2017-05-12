use strict;
use warnings;
use Test::More;

use DBI ':sql_types';

use DBIx::CSSQuery 'db';

my $dbh = DBI->connect("dbi:SQLite:dbname=t/read.sqlite3", "", "");

# :last
my $sth = $dbh->prepare("SELECT max(id) FROM posts");
$sth->execute;

my $max_id = $sth->fetchrow_hashref()->{'max(id)'};

db->attr(dbh => $dbh);

my $last = db("posts")->last->get(0);
is($last->{id}, $max_id);

done_testing;
