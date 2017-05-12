use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok( 'DateTime::Format::Diotek' ) }
my $dt = DateTime::Format::Diotek->parse_datetime('20120203065530');
isa_ok($dt, 'DateTime');
is($dt->ymd, '2012-02-03', 'date');
is($dt->hms, '06:55:30', 'time');
