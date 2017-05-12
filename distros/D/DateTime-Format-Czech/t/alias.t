use Test::Most;
use DateTime::Format::Czech;
use DateTime;

my $fmt = DateTime::Format::Czech->new;
ok $fmt->format(DateTime->now);

done_testing;
