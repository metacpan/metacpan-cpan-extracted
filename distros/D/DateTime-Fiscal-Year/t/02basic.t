use Test::More tests => 6;

use DateTime;
use DateTime::Fiscal::Year;
use strict;

# Jan 01 non-leap year as 1st day
{
my $dt = DateTime->new(year => 2003, month=> 01, day=>01);
my $dt2	= DateTime->new(year => 2003, month=> 01, day=>01);

my $fiscal = DateTime::Fiscal::Year->new(start => $dt);

is( $fiscal->day_of_fiscal_year( $dt2 ), 1,	'January 1 as day 1 non-leap' );
is( $fiscal->week_of_fiscal_year( $dt2 ), 1, 	'January 1 as day 1 non-leap week 1' );
}

# Dec 31 non-leap as last day
{
my $dt = DateTime->new(year => 2003, month=> 01, day=>01);
my $dt2 = DateTime->new(year => 2003, month=> 12, day=>31);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt );

is( $fiscal->day_of_fiscal_year( $dt2 ), 365,		'December 31 as day 365 non-leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 52, 		'December 31 as day 365 non-leap week 52' ); 
}

# Dec 31 of leap year 
{
my $dt = DateTime->new(year => 2004, month=> 01, day=>01);
my $dt2	= DateTime->new(year => 2004, month=> 12, day=>31);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt);

is( $fiscal->day_of_fiscal_year( $dt2 ), 366,		'December 31 as day 366 leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 52, 		'December 31 as day 366 leap week 52' ); 
}


