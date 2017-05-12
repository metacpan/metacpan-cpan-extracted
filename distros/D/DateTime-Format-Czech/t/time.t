use Test::Most;
use DateTime::Format::Czech;
use DateTime;

sub mktime {
    DateTime->new(year=>2010, month=>6, day=>13, @_);
}

my $f = DateTime::Format::Czech->new(show_date => 0, show_time => 1);
is $f->format_datetime(mktime(hour=> 9, minute=>15)),  '9.15';
is $f->format_datetime(mktime(hour=> 9, minute=> 1)),  '9.01';
is $f->format_datetime(mktime(hour=> 9, minute=> 0)),  '9.00';
is $f->format_datetime(mktime(hour=>19, minute=> 1)), '19.01';

done_testing;
