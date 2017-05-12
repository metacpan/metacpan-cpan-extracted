#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Date::Extract;

my %formats = (
    'today'    =>
        sub { is($_->ymd, DateTime->today->ymd, "today") },
    'tomorrow' =>
        sub { is($_->ymd, DateTime->today->add(days => 1)->ymd, "tomorrow") },
    'yesterday' =>
        sub { is($_->ymd, DateTime->today->add(days => -1)->ymd, "yesterday") },
    'last Friday' =>
        sub {
            is($_->day_name, 'Friday', "last Friday");
            cmp_ok($_->epoch, '<', DateTime->today->epoch, "last Friday");
        },
    'next Monday' =>
        sub {
            is($_->day_name, 'Monday', "next Monday");
            cmp_ok($_->epoch, '>', DateTime->today->epoch, "next Monday");
        },
    'previous Sat' => {
        TODO => 'Not handled by us or DTFN yet',
        test => sub {
            is($_->day_name, 'Saturday', "previous Sat");
            cmp_ok($_->epoch, '<', DateTime->today->epoch, "previous Sat");
        },
    },
    'Monday' =>
        sub { is($_->day_name, 'Monday', "Monday") },
    'Mon' =>
        sub { is($_->day_name, 'Monday', "Mon") },
    'November 13th, 1986' =>
        sub { is($_->ymd, '1986-11-13', "November 13th, 1986") },
    '13 November 1986' =>
        sub { is($_->ymd, '1986-11-13', "13 November 1986") },
    'Nov 13, 1986' =>
        sub { is($_->ymd, '1986-11-13', "Nov 13th, 1986") },
    'November 13th' =>
        sub { is($_->ymd, DateTime->today->year . '-11-13', "November 13th") },
    'Nov 13' =>
        sub { is($_->ymd, DateTime->today->year . '-11-13', "Nov 13") },
    '13 Nov' =>
        sub { is($_->ymd, DateTime->today->year . '-11-13', "13 Nov") },
    '13th November' =>
        sub { is($_->ymd, DateTime->today->year . '-11-13', "13th November") },
    '1986/11/13' =>
        sub { is($_->ymd, '1986-11-13', "1986/11/13") },
    '1986-11-13' =>
        sub { is($_->ymd, '1986-11-13', "1986-11-13") },
    '11-13-86' => {
        TODO => 'Not handled by us or DTFN yet',
        test => sub { is($_->ymd, '1986-11-13', "11-13-86") },
    },
    '11/13/1986' => {
        TODO => 'Not handled by us or DTFN yet',
        test => sub { is($_->ymd, '1986-11-13', "11/13/1986") },
    },
);

plan tests => 2 + 2 * keys(%formats);

while (my ($input, $checker) = each %formats) {
    $checker = { test => $checker }
        if ref $checker eq 'CODE';

    TODO: {
        local $TODO = $checker->{'TODO'} if $checker->{'TODO'};

        my $got = Date::Extract->extract($input);
        ok($got, "got a date out of $input");

        unless ($got) {
            fail("No date parsed, so no use running the checker");
            next;
        }

        local $_ = $got;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $checker->{'test'}->();
    }
}

