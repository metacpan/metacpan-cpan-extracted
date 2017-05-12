use utf8;
use Test::Most;
use DateTime::Format::Czech;
use DateTime;

my $f = DateTime::Format::Czech->new(show_time => 1, compound_format => '%s | %s');
is $f->format_datetime(DateTime->new(year=>2010, month=>6, day=>13, hour=>13, minute=>4)),
    '13. června | 13.04';

done_testing;
