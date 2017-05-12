use strict;
use warnings;
use Test::More;

use DBI;
use DBIx::CSSQuery 'db';

my $dbh = DBI->connect("dbi:SQLite:dbname=t/read.sqlite3", "", "", {AutoCommit => 1});
# my $sth = $dbh->prepare("SELECT max(id) FROM posts");
# $sth->execute;

db->attr(dbh => $dbh);

my $subject = __FILE__ ." Nihao $$ " . rand;

db("posts")->insert(
    subject => $subject,
    body    => "Lorem ipsum..."
);

my $last = db("posts")->last->get(0);

is($last->{subject}, $subject);

done_testing;
