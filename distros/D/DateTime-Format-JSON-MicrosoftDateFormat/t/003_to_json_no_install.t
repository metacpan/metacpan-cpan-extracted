# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 4;

use DateTime;
use DateTime::Format::JSON::MicrosoftDateFormat;

my $formatter=DateTime::Format::JSON::MicrosoftDateFormat->new;
isa_ok($formatter, "DateTime::Format::JSON::MicrosoftDateFormat");

my $dt=DateTime->new(qw{year 2014 month 2 day 17 hour 05 minute 16}, formatter=>$formatter);
isa_ok($dt, "DateTime");
ok(!$dt->can("TO_JSON"), "Cannot TO_JSON");
is($dt->iso8601, '2014-02-17T05:16:00');
