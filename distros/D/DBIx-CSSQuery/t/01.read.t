use strict;
use warnings;
use Test::More;

use DBI ':sql_types';

use DBIx::CSSQuery 'db';

plan tests => 4;

my $dbh = DBI->connect("dbi:SQLite:dbname=t/read.sqlite3", "", "");

my $sth = $dbh->prepare("SELECT * FROM posts WHERE id = ?");
$sth->bind_param(1, 1, SQL_INTEGER);

$sth->execute;

my $post = $sth->fetchrow_hashref();

db->attr(dbh => $dbh);

db("posts[id=1]")->each(
    sub{
        is_deeply($_[0], $post);
    }
);

{
    my ($the_post) = db("posts[id=1]")->get(0);
    is_deeply($the_post, $post);
}

{
    my $size = sub {
        my $sth = $dbh->prepare("SELECT count(*) FROM posts");
        $sth->execute;
        return $sth->fetchrow_arrayref()->[0];
    }->();

    my @all_ids = sub {
        my $ids = $dbh->selectall_arrayref("SELECT id FROM posts");
        return sort map { $_->[0] } @$ids;
    }->();

    is( db("posts")->size, $size);

    my @ids = ();
    db("posts")->each(
        sub {
            my $post = shift;
            push @ids, $post->{id};
        }
    );
    @ids = sort @ids;
    is_deeply(\@ids, \@all_ids );
}
