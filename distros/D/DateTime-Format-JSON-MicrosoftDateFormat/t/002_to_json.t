# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 5;

use DateTime;
use DateTime::Format::JSON::MicrosoftDateFormat (to_json=>1); 

my $formatter=DateTime::Format::JSON::MicrosoftDateFormat->new;
isa_ok($formatter, "DateTime::Format::JSON::MicrosoftDateFormat");

my $dt=DateTime->new(qw{year 2014 month 2 day 17 hour 05 minute 16}, formatter=>$formatter);
isa_ok($dt, "DateTime");
can_ok($dt, qw{TO_JSON});
is($dt->TO_JSON, '/Date(1392614160000)/');
is($dt->iso8601, '2014-02-17T05:16:00');
