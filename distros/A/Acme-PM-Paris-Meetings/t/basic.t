use strict;
use warnings;
use Test::More tests => 10;
use DateTime;
use Acme::PM::Paris::Meetings;


my $dt = DateTime->new(year => 2009,
                       month => 5,
                       day => 1,
                       time_zone => 'Europe/Paris');
isa_ok($dt, "DateTime");
# Basic DateTime check
is($dt->iso8601, "2009-05-01T00:00:00", "First of May 2009");

my $rec = Acme::PM::Paris::Meetings::recurrence($dt)->iterator;
can_ok($rec, 'next');
isa_ok($rec, 'DateTime::Set');


my $dt_meeting = $rec->next;
isa_ok($dt_meeting, "DateTime");
is($dt_meeting->iso8601, "2009-05-13T20:00:00", "Meeting of May 2009");
$dt_meeting = $rec->next;
isa_ok($dt_meeting, "DateTime");
is($dt_meeting->iso8601, "2009-06-10T20:00:00", "Meeting of June 2009");
$dt_meeting = $rec->next;
isa_ok($dt_meeting, "DateTime");
is($dt_meeting->iso8601, "2009-07-08T20:00:00", "Meeting of July 2009");
