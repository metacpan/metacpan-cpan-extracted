use strict;
use Test::More 'no_plan';

use Acme::PM::Berlin::Meetings;

{
    my @dts = next_meeting(1);
    is scalar(@dts), 1;
    isa_ok $dts[0], 'DateTime';
}

{
    my $now = DateTime->new(day => 31, month => 3, year => 2010, hour => 20, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2010-04-28T20:00:00';
}

{
    my $now = DateTime->new(day => 1, month => 12, year => 2014, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2015-01-07T20:00:00';
}

{
    my $now = DateTime->new(day => 29, month => 12, year => 2014, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2015-01-07T20:00:00';
}

{
    my $now = DateTime->new(day => 7, month => 1, year => 2015, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2015-01-28T20:00:00';
}

{
    my $now = DateTime->new(day => 8, month => 1, year => 2013, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2013-01-09T20:00:00', 'RT #61077';
}

{
    my $now = DateTime->new(day => 1, month => 2, year => 2016, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2016-02-24T19:00:00';
}

{
    my $now = DateTime->new(day => 27, month => 10, year => 2016, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2016-11-30T19:00:00';
}

{
    my $now = DateTime->new(day => 20, month => 11, year => 2016, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2016-11-30T19:00:00';
}

# Exception Aug 2020
{
    my $now = DateTime->new(day => 24, month => 8, year => 2020, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2020-08-25T19:00:00';
}

{
    my $now = DateTime->new(day => 25, month => 8, year => 2020, hour => 19, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    # is $dt, '2020-09-30T19:00:00'; --- another exception
    is $dt, '2020-09-23T18:00:00';
}

# Exception Sep 2020
{
    my $now = DateTime->new(day => 22, month => 9, year => 2020, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2020-09-23T18:00:00';
}

{
    my $now = DateTime->new(day => 24, month => 9, year => 2020, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2020-10-28T19:00:00';
}

# Switch from 19h -> 18h

{
    my $now = DateTime->new(day => 24, month => 3, year => 2023, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2023-03-29T19:00:00';
}

{
    my $now = DateTime->new(day => 24, month => 5, year => 2023, hour => 21, time_zone => 'Europe/Berlin');
    my $dt = Acme::PM::Berlin::Meetings::next_meeting_dt($now);
    is $dt, '2023-05-31T18:00:00';
}

__END__
