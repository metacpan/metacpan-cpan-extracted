
use Test;
use Date::Lima qw(beek_date daysmallest_conversions default_conversions);

plan tests => 4;

my $day = 60*60*24;
my $days_32 = 32*$day;

ok( beek_date($days_32),    "1mo2d" );
ok( beek_date("197:52:52"), "1w1d5h52m52s" );

daysmallest_conversions();

ok( beek_date($days_32),    "1mo2d" );
ok( beek_date("197:52:52"), "1w1d" );

