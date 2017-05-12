#!perl
#
# $Id$
#
use strict;
use warnings;

use Test::More tests => 31;
use DateTime;
use DateTime::Calendar::HalariSamvata;

my $dates = {
    '2008' => {
        '07' => [
            '2064 jyeShTa kR^iShNa 13',
            '2064 jyeShTa kR^iShNa 14',
            '2064 jyeShTa kR^iShNa 30',
            '2065 AShADha shukla 2',
            '2065 AShADha shukla 3',
            '2065 AShADha shukla 4',
            '2065 AShADha shukla 5',
            '2065 AShADha shukla 6',
            '2065 AShADha shukla 7',
            '2065 AShADha shukla 8',
            '2065 AShADha shukla 9',
            '2065 AShADha shukla 10',
            '2065 AShADha shukla 11',
            '2065 AShADha shukla 12',
            '2065 AShADha shukla adhika 12',
            '2065 AShADha shukla 13',
            '2065 AShADha shukla 14',
            '2065 AShADha shukla 15',
            '2065 AShADha kR^iShNa 1',
            '2065 AShADha kR^iShNa 2',
            '2065 AShADha kR^iShNa 3',
            '2065 AShADha kR^iShNa 4',
            '2065 AShADha kR^iShNa 5',
            '2065 AShADha kR^iShNa 6',
            '2065 AShADha kR^iShNa 7',
            '2065 AShADha kR^iShNa 8',
            '2065 AShADha kR^iShNa 9',
            '2065 AShADha kR^iShNa 11',
            '2065 AShADha kR^iShNa 12',
            '2065 AShADha kR^iShNa 13',
            '2065 AShADha kR^iShNa 14',
        ],
    },
};

foreach my $year (sort keys %{$dates}) {
    foreach my $month (sort keys %{$dates->{$year}}) {
        my $day = 0;    
        foreach my $expected (@{$dates->{$year}->{$month}}) {
            ++$day;
            my $dt = DateTime->new(day => $day, month => $month, year => $year, 
                time_zone => 'Asia/Kolkata');
            # sunrise at Mumbai
            my $date =
            DateTime::Calendar::HalariSamvata->from_object(
                object    => $dt,
                latitude  => '18.96',
                longitude => '72.82',
            );
            is($date->strftime("%x"), $expected, "$month $day, $year");
        }
    }
}

