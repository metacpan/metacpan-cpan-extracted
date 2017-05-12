
use Test;
use Time::DeltaString qw(delta_string daysmallest_conversions default_conversions);

plan tests => 4;

my $day = 60*60*24;
my $days_32 = 32*$day;

ok( delta_string($days_32),    "1mo2d" );
ok( delta_string("197:52:52"), "1w1d5h52m52s" );

daysmallest_conversions();

ok( delta_string($days_32),    "1mo2d" );
ok( delta_string("197:52:52"), "1w1d" );

