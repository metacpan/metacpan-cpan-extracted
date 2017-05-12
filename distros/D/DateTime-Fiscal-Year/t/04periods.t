use Test::More tests => 2;

use DateTime;
use DateTime::Fiscal::Year;

use strict;
# Calculate Period of Fiscal Year
{
my $dt = DateTime->new(year => 2003, month=> 02, day=>01);
my $dt2 = DateTime->new(year => 2003, month=> 04, day=>01);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt );

is( $fiscal->period_of_fiscal_year('12', $dt2), 3,		'Period of Fiscal Year' );
is( $fiscal->quarter_of_fiscal_year(12, $dt2), 1, 			'Quarter Fiscal Year' );
}
