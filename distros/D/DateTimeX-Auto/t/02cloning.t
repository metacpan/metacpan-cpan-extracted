use Test::More tests=>4;
use DateTimeX::Auto qw/:auto/;

my $from = '2010-06-01';
my $to   = '2010-12-01T00:00:00';

my $diff  = $to->delta_days($from)->in_units('days');

my $mid_date_1 = $from->clone->add(days => $diff/3);
my $mid_date_2 = $to->clone->subtract(days => $diff/3);

{
	no DateTimeX::Auto;
	
	is("$from",       '2010-06-01');
	is("$mid_date_1", '2010-08-01');
	is("$mid_date_2", '2010-10-01T00:00:00');
	is("$to",         '2010-12-01T00:00:00');
}
