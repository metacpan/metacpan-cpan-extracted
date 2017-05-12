#!perl
use strict;
use warnings;
use Test::More 0.88;
use Date::WeekNumber qw(iso_week_number cpan_week_number);

my $week;

my @TESTS =
(

    [
        [{ year => 2014, month => 12 }],
        q/you must specify year, month and day/,
        qq{hashref with year and month, but not day, should croak},
    ],

    [
        [{ year => 2014, day => 17 }],
        q/you must specify year, month and day/,
        qq{hashref with year and day, but not month, should croak},
    ],

    [
        [{ month => 12, day => 17 }],
        q/you must specify year, month and day/,
        qq{hashref with month and day, but not year, should croak},
    ],

    [
        [[year => 2014, quarter => 2, day => 1]],
        q/you can't pass a reference of type ARRAY/,
        qq{passing an ARRAY ref rather than a HASH ref should croak},
    ],

    [
        [ year => 2014, month => 12, other => 5 ],
        q/you must specify year, month and day/,
        qq{six args for a hash, without day, should croak},
    ],

    [
        [ year => 2014, other => 11, day => 17 ],
        q/you must specify year, month and day/,
        qq{six args for a hash, without month, should croak},
    ],

    [
        [ yyyy => 2014, month => 11, day => 17 ],
        q/you must specify year, month and day/,
        qq{six args for a hash, without year, should croak},
    ],

    [
        [ epoch => 1397257473 ],
        q/invalid arguments/,
        qq{wrong number of arguments should croak},
    ],


);

plan tests => 2 * int(@TESTS);

foreach my $test (@TESTS) {
    my ($argref, $pattern, $label) = @$test;
    my @args = @$argref;

    eval { $week = iso_week_number(@args) };
    ok(defined($@) && $@ =~ /\Q$pattern\E/, $label);

    eval { $week = cpan_week_number(@args) };
    ok(defined($@) && $@ =~ /\Q$pattern\E/, $label);

}
