use utf8;
use Test::Most;
use DateTime::Format::Czech;
use DateTime;

my $f = DateTime::Format::Czech->new(show_day_name => 1);
is $f->format_datetime(DateTime->new(year=>2010, month=>6, day=>13)), 'neděle 13. června';

done_testing;
