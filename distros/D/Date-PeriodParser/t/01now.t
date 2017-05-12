use Test::More tests=>5;
use_ok("Date::PeriodParser");
{
  $Date::PeriodParser::TestTime = $base = time;
  $Date::PeriodParser::TestTime = $base = time; # eliminate "used only once" warning
}

my($from, $to);
($from, $to) = parse_period("now");
is(scalar localtime $from, scalar localtime $base,
   "from is @{[scalar localtime $from]}");
is(scalar localtime $to, scalar localtime $base, 
   "to is @{[scalar localtime $to]}");
($from, $to) = parse_period("about now");
is(scalar localtime $from, scalar localtime $base - 5*60, 
   "from is @{[scalar localtime $from]}");
is(scalar localtime $to, scalar localtime $base + 5*60, 
   "to is @{[scalar localtime $to]}");
