#!/usr/bin/perl

package T::Date::Utils;

use Time::localtime;
use Moo;
use namespace::clean;

has 'months' => (is => 'rw', default => sub { [ '', qw(January February March April May June July August September October November December) ] });
has 'days'   => (is => 'ro', default => sub { [ qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)] });

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has day   => (is => 'rw', predicate => 1);

with 'Date::Utils';

sub BUILD {
    my ($self) = @_;

    if ($self->has_year && $self->has_month && $self->has_day) {
        $self->validate_year($self->year);
        $self->validate_month($self->month);
        if ($self->is_gregorian_leap_year($self->year)) {
            my $day = $self->day;
            die "ERROR: Invalid day [%s].", defined($day)?($day):(''), "\n"
                unless (defined($day) && ($day =~ /^\d+$/) && ($day >= 1) && ($day <= 29));
        }
        else {
            $self->validate_day($self->day);
        }
    }
    else {
        my $today = localtime;
        $self->year($today->year + 1900);
        $self->month($today->mon + 1);
        $self->day($today->mday);
    }
}

package main;

use 5.006;
use Test::More tests => 23;
use strict; use warnings;

my $t = T::Date::Utils->new;

is($t->gregorian_to_julian(2015, 4, 16), 2457128.5);

my @gregorian = $t->julian_to_gregorian(2457128.5);
is(join(', ', @gregorian), '2015, 4, 16');

ok(!!$t->is_gregorian_leap_year(2015) == 0);

is($t->jwday(2457102.5), 6);

is($t->get_month_number('January'), 1);
is($t->get_month_number('December'), 12);
is($t->get_month_number('MAY'), 5);
is($t->get_month_name(5), 'May');
is(T::Date::Utils->new(year => 2016, month => 4, day => 1)->get_month_name, 'April');

eval { $t->get_month_name(13) };
like($@, qr/ERROR: Invalid month/);

eval { $t->get_month_number('Max') };
like($@, qr/ERROR: Invalid month name/);

ok($t->validate_year(2015));
eval { $t->validate_year(-2015) };
like($@, qr/ERROR: Invalid year/);

ok($t->validate_month(10));
eval { $t->validate_month(13) };
like($@, qr/ERROR: Invalid month/);

eval { $t->validate_month(-1) };
like($@, qr/ERROR: Invalid month (?!name)/);

eval { $t->validate_month(+1) };
like($@, qr/(?!ERROR)/);

eval { $t->validate_month_name('Max') };
like($@, qr/ERROR: Invalid month name/);

eval { $t->validate_month_name('January') };
like($@, qr/^\s*$/);

eval { $t->validate_month('DECEMBER') };
like($@, qr/^\s*$/);

ok($t->validate_day(12));
eval { $t->validate_day(32) };
like($@, qr/ERROR: Invalid day/);

# Hijri Months
$t->months(
    [
     undef,
     q/Muharram/, q/Safar/ , q/Rabi' al-awwal/, q/Rabi' al-thani/,
     q/Jumada al-awwal/, q/Jumada al-thani/, q/Rajab/ , q/Sha'aban/,
     q/Ramadan/ , q/Shawwal/ , q/Dhu al-Qi'dah/ , q/Dhu al-Hijjah/
    ]);
is($t->get_month_number("Sha'aban"), 8);

done_testing;
