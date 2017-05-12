# -*- perl -*-

# t/010_patterns.t - check various patterns

use strict;
use warnings;
no warnings qw(once);

use Test::More tests => 1 + (6*4) + (33 * 3) + (18 * 2);
use Test::NoWarnings;

use lib qw(t/lib);
use testlib;

use DateTime::Format::CLDR;

my @patterns_date = (
    'ddMMyy',
    'dMMMy',
    'dMMMMy',
    'd\M\y',
    'y/M/d',
    'yMMdd',
    'yydM',
    'dddyyMMMM',
    'MMdy',
    'MMdyy',
    'M-dd-y',
    'MMMMdy',
    "'Hase'MMM'ist'dd'super'yy",
    "d¿M≠y",
    "d(M)y",
    "d{M}yyy",
    "dd MM yyy",
    "dd L yyy",
    "dd LLL yyy",
    "dd LLLL yyy",
    "dd.MM.yyy G Q",
    "dd.MM.yyy GGGG QQQ",
    "dd.MM.yyy GGGGG QQQQ",
    "dd.MM.yyy w q",
    "dd.MM.yyy W qqq",
    "dd.MM.yyy F qqqq",
    "dd.MM.yyy e",
    "dd.MM.yyy eee",
    "dd.MM.yyy eeee",
    "dd.MM.yyy c",
    "dd.MM.yyy ccc",
    "dd.MM.yyy cccc",
    "dd.MM.yyy D",
);

my @patterns_datetime = (
    'dd.MM.yyy hh:mm a',
    'dd.MM.yyy HH:mm',
    'dd.MM.yyy KK:mm a',
    'dd.MM.yyy kk:mm',
    'dd.MM.yyy jj:mm a',
    "dd.MM.yyy HH 'o''clock and 'mm'minutes'",
);

foreach my $pattern (@patterns_date) {
    my $dtf = DateTime::Format::CLDR->new(
        locale      => 'en_US',
        pattern     => $pattern,
    );

    my $dt1 = DateTime->new({
        year    => 2000,
        month   => 1,
        day     => 10,
    });
    my $dt2 = DateTime->new({
        year    => 1990,
        month   => 5,
        day     => 5,
    });
    my $dt3 = DateTime->new({
        year    => 2010,
        month   => 10,
        day     => 31,
    });

    testlib::compare($dtf,$dt1,"Pattern $pattern for dt1 ok");
    testlib::compare($dtf,$dt2,"Pattern $pattern for dt2 ok");
    testlib::compare($dtf,$dt3,"Pattern $pattern for dt3 ok");

    if ($pattern =~ /yyy+/) {
        my $dt4 = DateTime->new({
            year    => 600,
            month   => 10,
            day     => 31,
        });
        my $dt5 = DateTime->new({
            year    => -100,
            month   => 10,
            day     => 31,
        });


        testlib::compare($dtf,$dt4);
        testlib::compare($dtf,$dt5);
    }
}

foreach my $pattern (@patterns_datetime) {
    my $dtf = DateTime::Format::CLDR->new(
        locale      => 'en_US',
        pattern     => $pattern,
    );

    my $dt1 = DateTime->new({
        year    => 2000,
        month   => 1,
        day     => 10,
        hour    => 0,
        minute  => 30,
    });
    my $dt2 = DateTime->new({
        year    => 1990,
        month   => 5,
        day     => 5,
        hour    => 10,
        minute  => 35,
    });
    my $dt3 = DateTime->new({
        year    => 2010,
        month   => 10,
        day     => 31,
        hour    => 15,
        minute  => 40,
    });
    my $dt4 = DateTime->new({
        year    => 2010,
        month   => 10,
        day     => 31,
        hour    => 23,
        minute  => 45,
    });

    testlib::compare($dtf,$dt1,"Pattern $pattern for dt1 ok");
    testlib::compare($dtf,$dt2,"Pattern $pattern for dt2 ok");
    testlib::compare($dtf,$dt3,"Pattern $pattern for dt3 ok");
    testlib::compare($dtf,$dt4,"Pattern $pattern for dt4 ok");
}