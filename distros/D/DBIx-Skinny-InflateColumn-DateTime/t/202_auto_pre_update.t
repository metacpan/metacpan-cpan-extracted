use strict;
use lib './t';
use Test::More tests => 3;

use Mock::SQLite;
use Mock::Auto;

use DateTime;
use DateTime::TimeZone;

note 'pre_update trigger';
{
    my $timezone = DateTime::TimeZone->new(name => 'local');
    my $now = DateTime->now(time_zone => $timezone)->epoch;

    my $book = Mock::Auto->single('books', { id => 2 });
    my $old_time = $book->updated_at->epoch;
    my $old_created_time = $book->created_at->epoch;
    ok $old_time < $now, 'record updated in the past ';
    $book->update({ name => 'book2_updated' });

    my $new_book = Mock::Auto->single('books', { id => 2 });
    ok $new_book->updated_at->epoch >= $now, 'updated_at auto insert ok';
    is $new_book->created_at->epoch, $old_created_time, 'no update created_at';
}
