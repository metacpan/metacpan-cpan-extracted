use Test::More tests=>2;
use Date::PeriodParser;

my $now = time;
my($from, $to);
($from, $to) = parse_period("now");
is $from, $now, "got current time ...";
is $to, $now, "... both times";
