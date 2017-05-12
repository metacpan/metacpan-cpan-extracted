use strict;
use lib './t';
use Test::More;

use Mock::SQLite;
use Mock::AutoRules;

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
    Mock::AutoRules->insert('books', $params);
    my $book = Mock::AutoRules->single('books', { id => 4 });
    is $book->created_at, undef, 'created_at no auto insert ok';
    is $book->updated_at, undef, 'updated_at no auto insert ok';
    ok $book->published_at->epoch >= $now, 'published_at auto insert ok';

    $params = {
        id   => 3,
        name => 'Kate',
    };
    Mock::AutoRules->insert('authors', $params);
    my $author = Mock::AutoRules->single('authors', { id => 3 });
    is $author->created_on, undef, 'created_on no auto insert ok';
    is $author->updated_on, undef, 'updated_on no auto insert ok';
    ok $author->debuted_on->epoch >= $now, 'debuted_on auto insert ok';
}

done_testing;
