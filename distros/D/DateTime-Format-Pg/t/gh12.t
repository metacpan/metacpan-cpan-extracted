use strict;
use Test::More;

use_ok('DateTime::Format::Pg');

# https://www.postgresql.org/docs/9.5/static/datatype-datetime.html#DATATYPE-INTERVAL-INPUT
my $offset = '1095 days 13:37:28.36922';
my $duration;
eval {
    $duration = DateTime::Format::Pg->parse_duration($offset);
};
my $e = $@;
if (! ok !$e, "should succeed parsing '$offset' without errors") {
    diag $e;
}

is $duration->seconds, 28, "seconds should be '28'";
is $duration->nanoseconds, 369220000, "nano-seconds should be '369220000'";

done_testing;
