use strict;
use lib './t';
use Test::More tests => 4;

use Mock::SQLite;
use Mock::DB;

use DateTime;
use DateTime::TimeZone;

note 'pre_insert trigger';
{
    my $params = {
        id        => 4,
        author_id => 1,
        name      => 'book4',
    };
    Mock::DB->insert('books', $params);
    my $book = Mock::DB->single('books', { id => 4 });
    is $book->created_at, undef, 'created_at is empty';
    is $book->updated_at, undef, 'created_at is empty';

    $params = {
        id   => 3,
        name => 'Kate',
    };
    Mock::DB->insert('authors', $params);
    my $author = Mock::DB->single('authors', { id => 3 });
    is $author->created_on, undef, 'created_on is empty';
    is $author->updated_on, undef, 'created_on is empty';
}
