use Test::More tests => 14;

use DateTime;
use DateTime::Fiscal::Year;
use strict;

# Feb 1 as day 1 
{
my $dt = DateTime->new(year => 2003, month=> 02, day=>01);
my $dt2	= DateTime->new(year => 2003, month=> 02, day=>01);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt );

is( $fiscal->day_of_fiscal_year( $dt2 ), 1,		'Feb 1 as day 1 non-leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 1, 		'Feb 1 as day 1 non-leap week 1' ); 
}


# Feb 28 as day 28 non leap
{
my $dt = DateTime->new(year => 2003, month=> 02, day=>01);
my $dt2	= DateTime->new(year => 2003, month=> 02, day=>28);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt );

is( $fiscal->day_of_fiscal_year( $dt2 ), 28,		'Feb 28 as day 28 non leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 4, 		'Feb 28 as day 28 non-leap week 4' ); 
}

# Feb 29 as day 29 leap 
{
my $dt = DateTime->new(year => 2004, month=> 02, day=>01);
my $dt2	= DateTime->new(year => 2004, month=> 02, day=>29);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt );

is( $fiscal->day_of_fiscal_year( $dt2 ), 29,		'Feb 29 as day 29 leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 5, 		'Feb 29 as day 29 leap week 5' ); 
}

# Mar 1 as day 29 non leap 
{
my $dt = DateTime->new(year => 2003, month=> 02, day=>01);
my $dt2	= DateTime->new(year => 2003, month=> 03, day=>01);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt);

is( $fiscal->day_of_fiscal_year( $dt2 ), 29,		'Mar 1 as day 29 non-leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 5, 		'Mar 1 as day 29 non-leap week 5' ); 
}

# Mar 1 as day 30 leap
{
my $dt = DateTime->new(year => 2004, month=> 02, day=>01);
my $dt2	= DateTime->new(year => 2004, month=> 03, day=>01);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt);

is( $fiscal->day_of_fiscal_year( $dt2 ), 30,		'Mar 1 as day 30 leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 5, 		'Mar 1 as day 30 leap week 5' ); 
}

# Jan 31 as day 365 non-leap 
{
my $dt = DateTime->new(year => 2003, month=> 02, day=>01);
my $dt2	= DateTime->new(year => 2004, month=> 01, day=>31);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt );

is( $fiscal->day_of_fiscal_year( $dt2 ), 365,		'Jan 31 as day 365 non-leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 52, 		'Jan 31 as day 365 non-leap week 52' ); 
}

# Jan 31 as day 366 leap 
{
my $dt = DateTime->new(year => 2004, month=> 02, day=>01);
my $dt2	= DateTime->new(year => 2005, month=> 01, day=>31);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt );

is( $fiscal->day_of_fiscal_year( $dt2 ), 366,		'Jan 31 as day 366 leap' ); 
is( $fiscal->week_of_fiscal_year( $dt2 ), 52, 		'Jan 31 as day 366 leap Week 52' ); 
}

# Try something different
#{
#use DateTime::Calendar::Julian;
#my $sfy = DateTime::Calendar::Julian->new(year=>1752, month=>10, day=>4);
#my $td = DateTime->new(year=>1752, month=>10, day=>4);

#my $dtfy = DateTime::Fiscal::Year->new(fiscal_start => $sfy, target_date => $td);

#is( $dtfy->day_of_fiscal_year,366,		'julian to greg days' ); 
#is( $dtfy->week_of_fiscal_year,52, 		'julian to greg week' ); 
#}
