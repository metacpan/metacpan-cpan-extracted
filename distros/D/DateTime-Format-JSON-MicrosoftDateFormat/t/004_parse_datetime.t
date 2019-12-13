# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 38;

use DateTime::Format::JSON::MicrosoftDateFormat;

my $formatter=DateTime::Format::JSON::MicrosoftDateFormat->new;

{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1392614160000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-17T05:16:00', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1392614160000-0000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-17T05:16:00', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1392614160000+0000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-17T05:16:00', "iso8601");
}

{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1392089278000-0600)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-10T21:27:58', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1392067678123)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-10T21:27:58', "iso8601");
is($dt->millisecond, '123', "milliseconds");
is($dt->microsecond, '123000', "microseconds");
#is($dt->nanosecond, '123000000', "nanoseconds"); #rounding issue DateTime->from_epoch 0.4501
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1392067678000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-10T21:27:58', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1392064078000+0100)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '2014-02-10T21:27:58', "iso8601");
}

{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(0)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '1970-01-01T00:00:00', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(0+0000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '1970-01-01T00:00:00', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(0-0000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '1970-01-01T00:00:00', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(0+0100)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '1970-01-01T01:00:00', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(0-0100)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '1969-12-31T23:00:00', "iso8601");
}

{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(-1000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '1969-12-31T23:59:59', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(-1000+0000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '1969-12-31T23:59:59', "iso8601");
}
{
my $dt=DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(-1000-0000)/");
isa_ok($dt, "DateTime");
is($dt->iso8601, '1969-12-31T23:59:59', "iso8601");
}
{
local $@;
my $dt=eval 'DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1576075564-XXXX)/")';
my $error = $@;
is($dt, undef, 'Invalid time zone return');
like($error, qr/Invalid JSON MicrosoftDateFormat string/, 'Invalid string time zone error');
}
{
local $@;
my $dt=eval 'DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(1576075564A)/")';
my $error = $@;
is($dt, undef, 'Invalid string epoch return');
like($error, qr/Invalid JSON MicrosoftDateFormat string/, 'Invalid string epoch error');
}
{
local $@;
my $dt=eval 'DateTime::Format::JSON::MicrosoftDateFormat->parse_datetime("/Date(a1576075564)/")';
my $error = $@;
is($dt, undef, 'Invalid string epoch return');
like($error, qr/Invalid JSON MicrosoftDateFormat string/, 'Invalid string epoch error');
}
