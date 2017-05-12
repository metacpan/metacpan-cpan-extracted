use strict;
use lib './t';
use Test::More;

use Mock::SQLite;
use Mock::AutoRules;

use DateTime;
use DateTime::TimeZone;

note 'pre_update trigger';
{
    my $timezone = DateTime::TimeZone->new(name => 'local');
    my $now = DateTime->now(time_zone => $timezone)->epoch;

    my $book = Mock::AutoRules->single('books', { id => 2 });
    my $old_time = $book->published_at->epoch;
    my $old_created_time = $book->created_at->epoch;
    ok $old_time < $now, 'record updated in the past ';
    $book->update({ name => 'book2_updated' });

    my $new_book = Mock::AutoRules->single('books', { id => 2 });
    ok $new_book->published_at->epoch >= $now, 'published_at auto update ok';
    is $new_book->created_at->epoch, $old_created_time, 'no update created_at';

    my $author = Mock::AutoRules->single('authors', { id => 2 });
    my $old_debuted_on_time = $author->debuted_on->epoch;
    $author->update({name => 'author_updated'});

    my $new_author = Mock::AutoRules->single('authors', { id => 2 });
    is $new_author->name, 'author_updated', 'check updated';
    is $new_author->debuted_on->epoch, $old_debuted_on_time, 'no update debuted_on';


}

done_testing;
