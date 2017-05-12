use Test::More tests=>5;
use_ok("Date::PeriodParser");

my ($from, $to) = parse_period("sometime");
is(scalar localtime $from, scalar localtime 0, 
   "from is @{[scalar localtime $from]}");
is(scalar localtime $to, scalar localtime 2**31-1, 
   "to is @{[scalar localtime $to]}");
($from, $to) = parse_period("circa sometime");
is(scalar localtime $from, scalar localtime 0, 
   "from is @{[scalar localtime $from]}");
is(scalar localtime $to, scalar localtime 2**31-1, 
   "to is @{[scalar localtime $to]}");
