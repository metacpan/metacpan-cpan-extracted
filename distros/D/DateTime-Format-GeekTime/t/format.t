#!perl
use Test::More tests=>17;
use DateTime;
use DateTime::Format::GeekTime;

{
my $dt=DateTime->new(year=>2010,month=>3,day=>8,
                     hour=>17,minute=>56,second=>23,
                     time_zone=>'Europe/Rome',
                 );
is(DateTime::Format::GeekTime->format_datetime($dt),
   "0xB4B1 on day 0x042 \x{b4b1}");
}

{
my $format=DateTime::Format::GeekTime->new(2010);
my $dt=$format->parse_datetime("0xB4B1 0x0042 \x{b4b0}");
is($dt->month,3);
is($dt->day,8);
is($dt->hour,16);
is($dt->minute,56);
is($dt->second,23);
is($dt->time_zone->name,'UTC');

my $other=$format->parse_datetime("0xB4B1 0x0042");
cmp_ok($dt,'==',$other);
$other=$format->parse_datetime("0xB4B1 on day 0x0042");
cmp_ok($dt,'==',$other);
$other=$format->parse_datetime("B4B1 0042");
cmp_ok($dt,'==',$other);
$other=$format->parse_datetime("B4B10042");
cmp_ok($dt,'==',$other);
$other=$format->parse_datetime("b4b10042");
cmp_ok($dt,'==',$other);
$other=$format->parse_datetime("0xB4B1 0x042");
cmp_ok($dt,'==',$other);
$other=$format->parse_datetime("B4B1 042");
cmp_ok($dt,'==',$other);
$other=$format->parse_datetime("B4B1042");
cmp_ok($dt,'==',$other);
$other=$format->parse_datetime("b4b1042");
cmp_ok($dt,'==',$other);
}

{ # bad codepoint
my $dt=DateTime::Format::GeekTime->parse_datetime('0xdc01 0x000');
is(DateTime::Format::GeekTime->format_datetime($dt),
   '0xDC01 on day 0x000');
}
