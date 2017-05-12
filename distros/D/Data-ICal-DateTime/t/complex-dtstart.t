use strict;

use Test::More tests => 2;

use DateTime;
use Data::ICal;
use Data::ICal::DateTime;

my $d = Data::ICal->new( filename => 't/ics/test.ics' );

my $st = DateTime->new(
    year => 2014, month  =>  1, day    =>  2,
    hour => 12,   minute => 34, second => 56,
    time_zone => 'America/Chicago',
);

my ($e) = $d->events;
$e->start($st);

my $dtstart = $e->property('dtstart')->[0];
is($dtstart->value, '20140102T123456');
is($dtstart->parameters->{TZID}, 'America/Chicago');
