use Test::More tests=>6;
use Date::PeriodParser;

# zero leeway
my($from,$to);
($from, $to) = Date::PeriodParser::_apply_leeway(1000, 1000, 0);
is $from, 1000, 'zero lower leeway right';
is $to, 1000, 'zero upper leeway right';

# positive leeway
($from, $to) = Date::PeriodParser::_apply_leeway(1000, 1000, 1000);
is $from, 0, 'positive lower leeway right';
is $to, 2000, 'positive upper leway right';

# negative leeway - not used, but edge case
($from, $to) = Date::PeriodParser::_apply_leeway(1000, 1000, -1000);
is $from, 2000, 'negative lower leeway right';
is $to, 0,' negative upper leeway right';
