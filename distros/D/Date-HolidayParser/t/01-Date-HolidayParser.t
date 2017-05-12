#!perl
use strict;
use warnings;
use Test::More;
use Date::HolidayParser;
use FindBin;
require $FindBin::RealBin.'/basicTest.pm';

plan tests => 30;

my $parser = Date::HolidayParser->new("$FindBin::RealBin/testholiday");

ok(defined $parser, "->new returned something usable");
ok(!$parser->silent,'Silent should be false');
isa_ok($parser,'Date::HolidayParser');

my $silentParser = Date::HolidayParser->new("$FindBin::RealBin/testholiday", silent => 1);
ok(defined $silentParser, "->new(file, silent => 1) returned something usable");
ok($silentParser->silent,'Silent should be true');
isa_ok($silentParser,'Date::HolidayParser');

runTests($parser);

1;
