use strict;
use lib './t';
use Test::More tests => 19;

use Mock::SQLite;
use Mock::DB;

note 'inflate/deflate test for created_at';
{
    my $book = Mock::DB->single('books', { id => 1 });
    isa_ok $book->created_at, 'DateTime';
    is $book->created_at->ymd, '2009-01-01', 'created_at inflate ok';

    my $dt = $book->created_at;
    $dt->add(months => 2);
    $book->set({ created_at => $dt });
    isa_ok $book->created_at, 'DateTime';
    is $book->created_at->ymd, '2009-03-01', 'column value is updated';

    ok $book->update({ created_at => $dt }), 'created_at deflate ok';
    isa_ok $book->created_at, 'DateTime';
    is $book->created_at->ymd, '2009-03-01', 'row data is already updated';

    my $updated = Mock::DB->single('books', { id => 1 });
    isa_ok $updated->created_at, 'DateTime';
    is $updated->created_at->ymd, '2009-03-01', 'DB record is updated';
}

note 'inflate test other columns';
{
    my $book = Mock::DB->single('books', { id => 2 });
    isa_ok $book->published_at, 'DateTime';
    isa_ok $book->updated_at,   'DateTime';
    is $book->published_at->ymd, '2008-01-01', 'published_at inflate ok';
    is $book->updated_at->ymd,   '2009-01-02', 'updated_at inflate ok';

    my $author = Mock::DB->single('authors', { id => 1 });
    isa_ok $author->debuted_on, 'DateTime';
    isa_ok $author->created_on, 'DateTime';
    isa_ok $author->updated_on, 'DateTime';
    is $author->debuted_on->ymd, '2008-02-01', 'debuted_on inflate ok';
    is $author->created_on->ymd, '2009-02-01', 'created_on inflate ok';
    is $author->updated_on->ymd, '2009-02-02', 'updated_on inflate ok';
}

