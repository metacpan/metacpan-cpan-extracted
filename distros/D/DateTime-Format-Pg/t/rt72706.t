use strict;
use Test::More;

use_ok "DateTime::Format::Pg";

subtest 'positive offset' => sub {
    my $dt = DateTime::Format::Pg->parse_datetime( "1894-01-01 00:00:00+05:17:32" );
    ok $dt, "Parse ok";
    is $dt->offset(), ((5*60+17)*60)+32, 'tz offset';
};

subtest 'negative offset' => sub {
    my $dt = DateTime::Format::Pg->parse_datetime( "1894-01-01 00:00:00-05:17:32" );
    ok $dt, "Parse ok";
    is $dt->offset(), -1 * (((5*60+17)*60)+32), 'tz offset';
};

done_testing;