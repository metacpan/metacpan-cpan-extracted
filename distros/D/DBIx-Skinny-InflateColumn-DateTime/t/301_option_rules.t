use strict;
use lib './t';
use Test::More;

use Mock::SQLite;
use Mock::Rules;

note 'inflate/deflate test for created_at';
{
    my $book = Mock::Rules->single('books', { id => 1 });
    isa_ok $book->created_at, 'DateTime';
    isnt $book->created_at, '2009-01-01 10:00:00';
    is $book->updated_at, '2009-01-02 11:00:00';
}

note 'inflate/deflate auto test for created_at';
{
    my $book = Mock::Rules::Auto->single('books', { id => 1 });
    isa_ok $book->created_at, 'DateTime';
    isnt $book->created_at, '2009-01-01 10:00:00';
    is $book->updated_at, '2009-01-02 11:00:00';
}

done_testing;
