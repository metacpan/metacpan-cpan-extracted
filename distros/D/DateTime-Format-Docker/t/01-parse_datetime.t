use Test::More tests => 2;
use DateTime::Format::Docker;

my $dt;

$dt = DateTime::Format::Docker->parse_datetime('2017-01-12T20:25:26.027337914Z');
is($dt->ymd(), '2017-01-12');

$dt = DateTime::Format::Docker->parse_datetime('2017-01-12T20:25:26Z');
is($dt->ymd(), '2017-01-12');
