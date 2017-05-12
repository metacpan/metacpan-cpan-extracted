use strict;
use lib './t';
use Test::More tests => 3;

use Mock::SQLite;
use Mock::DB;

use DateTime;
use DateTime::TimeZone;

note 'pre_update trigger';
{
    my $timezone = DateTime::TimeZone->new(name => 'local');
    my $now = DateTime->now(time_zone => $timezone)->epoch;

    my $book = Mock::DB->single('books', { id => 2 });
    my $old_time = $book->updated_at->epoch;
    ok $old_time < $now, 'record updated in the past ';
    $book->update({ name => 'book2_updated' });

    my $new_book = Mock::DB->single('books', { id => 2 });
    is $new_book->name, 'book2_updated', 'updated record found';
    is $new_book->updated_at->epoch, $old_time, 'updated_at is same to before update';
}
