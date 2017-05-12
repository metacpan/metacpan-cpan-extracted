# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 16;

use DateTime;
use DateTime::Format::JSON::MicrosoftDateFormat;

my $formatter=DateTime::Format::JSON::MicrosoftDateFormat->new;

{
my $dt=DateTime->new(year=>2014, month=>2, day=>17, hour=>5, minute=>16, formatter=>$formatter);
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-17T05:16:00', "iso8601");
is("$dt", "/Date(1392614160000)/", "stringify overload");
is($dt->_stringify, "/Date(1392614160000)/", "stringify overload");
}

{
my $dt=DateTime->new(year=>1970, month=>1, day=>1, formatter=>$formatter);
isa_ok($dt, "DateTime");
is($dt->iso8601, '1970-01-01T00:00:00', "iso8601");
is("$dt", "/Date(0)/", "stringify overload");
is($dt->_stringify, "/Date(0)/", "stringify overload");
}

{
my $dt=DateTime->new(year=>1969, month=>11, day=>19, hour=>6, minute=>53, formatter=>$formatter);
isa_ok($dt, "DateTime");
is($dt->iso8601, '1969-11-19T06:53:00', "iso8601");
is("$dt", "/Date(-3690420000)/", "stringify overload");
is($dt->_stringify, "/Date(-3690420000)/", "stringify overload");
}

{
my $dt=DateTime->new(year=>2014, month=>2, day=>17, hour=>5, minute=>16, formatter=>$formatter, time_zone => "EST5EDT");
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-17T05:16:00', "iso8601");
is("$dt", "/Date(1392632160000)/", "stringify overload");
is($dt->_stringify, "/Date(1392632160000)/", "stringify overload");
}

