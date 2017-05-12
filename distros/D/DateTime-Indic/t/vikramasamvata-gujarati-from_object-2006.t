#!perl
#
# $Id$
#
use strict;
use warnings;

use Test::More tests => 61;
use DateTime;
use DateTime::Calendar::VikramaSamvata::Gujarati;

# Source Janmabhoomi Panchanga (2007-2009)
my $dates = {
    '11' => [
        '2063 kArtika shukla 10',
        '2063 kArtika shukla 11',
        '2063 kArtika shukla 13',
        '2063 kArtika shukla 14',
        '2063 kArtika shukla 15',
        '2063 kArtika kR^iShNa 1',
        '2063 kArtika kR^iShNa 2',
        '2063 kArtika kR^iShNa 3',
        '2063 kArtika kR^iShNa 4',
        '2063 kArtika kR^iShNa 5',
        '2063 kArtika kR^iShNa 6',
        '2063 kArtika kR^iShNa 7',
        '2063 kArtika kR^iShNa 8',
        '2063 kArtika kR^iShNa 9',
        '2063 kArtika kR^iShNa 10',
        '2063 kArtika kR^iShNa 11',
        '2063 kArtika kR^iShNa 12',
        '2063 kArtika kR^iShNa 13',
        '2063 kArtika kR^iShNa 14',
        '2063 kArtika kR^iShNa 30',
        '2063 mArgashIrasa shukla 1',
        '2063 mArgashIrasa shukla 2',
        '2063 mArgashIrasa shukla 3',
        '2063 mArgashIrasa shukla 4',
        '2063 mArgashIrasa shukla 5',
        '2063 mArgashIrasa shukla 6',
        '2063 mArgashIrasa shukla 7',
        '2063 mArgashIrasa shukla 8',
        '2063 mArgashIrasa shukla 9',
        '2063 mArgashIrasa shukla 10',
    ],
    '12' => [
        '2063 mArgashIrasa shukla 11',
        '2063 mArgashIrasa shukla 12',
        '2063 mArgashIrasa shukla 13',
        '2063 mArgashIrasa shukla 14',

        '2063 mArgashIrasa kR^iShNa 1',
        '2063 mArgashIrasa kR^iShNa 2',
        '2063 mArgashIrasa kR^iShNa 3',
        '2063 mArgashIrasa kR^iShNa 4',
        '2063 mArgashIrasa kR^iShNa 5',
        '2063 mArgashIrasa kR^iShNa 6',
        '2063 mArgashIrasa kR^iShNa 7',
        '2063 mArgashIrasa kR^iShNa 8',
        '2063 mArgashIrasa kR^iShNa adhika 8',
        '2063 mArgashIrasa kR^iShNa 9',
        '2063 mArgashIrasa kR^iShNa 10',
        '2063 mArgashIrasa kR^iShNa 11',
        '2063 mArgashIrasa kR^iShNa 12',
        '2063 mArgashIrasa kR^iShNa 13',
        '2063 mArgashIrasa kR^iShNa 14',
        '2063 mArgashIrasa kR^iShNa 30',

        '2063 pauSha shukla 1',
        '2063 pauSha shukla 2',
        '2063 pauSha shukla 3',
        '2063 pauSha shukla 4',
        '2063 pauSha shukla 5',
        '2063 pauSha shukla 6',
        '2063 pauSha shukla 7',
        '2063 pauSha shukla 8',
        '2063 pauSha shukla 10',
        '2063 pauSha shukla 11',
        '2063 pauSha shukla 12',
    ],
};

foreach my $month (sort keys %{$dates}) {
    my $day = 0;    
    foreach my $expected (@{$dates->{$month}}) {
        ++$day;
        my $dt = DateTime->new(day => $day, month => $month, year => 2006, 
            time_zone => 'Asia/Kolkata');
        # sunrise at Mumbai
        my $date =
        DateTime::Calendar::VikramaSamvata::Gujarati->from_object(
            object    => $dt,
            latitude  => '18.96',
            longitude => '72.82',
        );
        is($date->strftime("%x"), $expected, "$month $day, 2006");
    }
}
