use strict;
use lib './t';
use Test::More tests => 4;

use Mock::SQLite;
use Mock::Auto;

use DateTime;
use DateTime::TimeZone;

note 'pre_insert trigger';
{
    my $timezone = DateTime::TimeZone->new(name => 'local');
    my $now = DateTime->now(time_zone => $timezone)->epoch;

    my $params = {
        id        => 4,
        author_id => 1,
        name      => 'book4',
    };
    Mock::Auto->insert('books', $params);
    my $book = Mock::Auto->single('books', { id => 4 });
    ok $book->created_at->epoch >= $now, 'created_at auto insert ok';
    ok $book->updated_at->epoch >= $now, 'updated_at auto insert ok';

    $params = {
        id   => 3,
        name => 'Kate',
    };
    Mock::Auto->insert('authors', $params);
    my $author = Mock::Auto->single('authors', { id => 3 });
    ok $author->created_on->epoch >= $now, 'created_on auto insert ok';
    ok $author->updated_on->epoch >= $now, 'updated_on auto insert ok';
}
