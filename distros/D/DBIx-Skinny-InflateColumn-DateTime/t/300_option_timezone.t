use strict;
use lib './t';
use Test::More;

use Mock::SQLite;
use Mock::TimeZone;

note 'inflate/deflate test for created_at';
{
    my $book = Mock::TimeZone->single('books', { id => 1 });
    isa_ok $book->created_at, 'DateTime';
    is $book->created_at->ymd, '2009-01-01', 'created_at inflate ok';
    isa_ok $book->created_at->time_zone, 'DateTime::TimeZone::Asia::Taipei', 'time_zone';
}

note 'inflate/deflate auto test for created_at';
{
    my $book = Mock::TimeZone::Auto->single('books', { id => 1 });
    isa_ok $book->created_at, 'DateTime';
    is $book->created_at->ymd, '2009-01-01', 'created_at inflate ok';
    isa_ok $book->created_at->time_zone, 'DateTime::TimeZone::Asia::Taipei', 'time_zone';
}

done_testing;
