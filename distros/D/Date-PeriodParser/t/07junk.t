use Test::More tests=>8;
use Date::PeriodParser;

my($from, $to);
($from, $to) = parse_period();
is $from, -1, "detected gibberish as expected";
is $to, "You didn't supply an argument.", "proper error message";
($from, $to) = parse_period("");
is $from, -1, "detected gibberish as expected";
is $to, "You didn't supply an argument.", "proper error message";
($from, $to) = parse_period("        ");
is $from, -1, "detected gibberish as expected";
is $to, "You didn't supply an argument.", "proper error message";
($from, $to) = parse_period("complete nonsense");
is $from, -1, "detected gibberish as expected";
is $to, "I couldn't parse that at all.", "proper error message";
