#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 30;
use DateTime;
use DateTime::Calendar::Discordian;

my $dt;
my $dtcd;
my @testdates = (
    [3,  13], [3,  14], [3,  15],
    [5,  25], [5,  26], [5,  27],
    [8,   6], [8,   7], [8,   8],
    [10, 18], [10, 19], [10, 20],
    [12, 30], [12, 31], [1,   1],
);

foreach my $year (2004, 2006)
{
    foreach my $date (@testdates)
    {
        $dt = DateTime->new( year   => $year,
                             month  => $date->[0],
                             day    => $date->[1],
                           );
        eval { 
            $dtcd = DateTime::Calendar::Discordian->from_object(object => $dt); 
        };
        ok($@ eq "", 'Discordian Calendar Object created') 
        or diag(($dt->utc_rd_values)[0] . ' '
           . join('/', $year, $date->[0], $date->[1]) . ": $@");
    }
}
