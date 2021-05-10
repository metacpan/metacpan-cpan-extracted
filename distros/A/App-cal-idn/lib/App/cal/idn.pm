package App::cal::idn;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-03'; # DATE
our $DIST = 'App-cal-idn'; # DIST
our $VERSION = '0.136'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';

use Calendar::Indonesia::Holiday qw(list_idn_holidays);
use DateTime;
use List::Util qw(max);
use Term::ANSIColor;
use Text::ANSI::Util qw(ta_length);

my $month_names = [qw(Januari Februari Maret April Mei Juni Juli Agustus September Oktober November Desember)];
my $short_month_names = [qw(Jan Feb Mar Apr Mei Jun Jul Agt Sep Okt Nov Des)];

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Display Indonesian calendar on the command-line',
};

sub _center {
    my ($w, $text) = @_;
    my $tw = length($text);
    sprintf("%s%s%s",
            (" " x int(($w-$tw)/2)),
            $text,
            (" " x int(($w-$tw)/2)),
        );
}

sub _rpad {
    my ($w, $text) = @_;
    sprintf("%s%s", $text, " " x ($w-ta_length($text)));
}

$SPEC{gen_monthly_calendar} = {
    v => 1.1,
    summary => 'Generate a single month calendar',
    description => <<'_',

Return [\@lines, \@hol]

_
    args => {
        month => {
            schema => ['int*' => between => [1, 12]],
            req => 1,
        },
        year => {
            schema => ['int*'],
            req => 1,
        },
        show_year_in_title => {
            schema => ['bool', default => 1],
        },
        show_prev_month_days => {
            schema => ['bool', default => 1],
        },
        show_next_month_days => {
            schema => ['bool', default => 1],
        },
        show_holiday_list => {
            schema => ['bool', default => 1],
        },
        show_joint_leave => {
            schema => ['bool', default => 0],
        },
        highlight_today => {
            schema => [bool => default => 1],
        },
        time_zone => {
            schema => 'str*',
        },
    },
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
    result_naked => 1,
};
sub gen_monthly_calendar {
    my %args = @_;
    my $m = $args{month};
    my $y = $args{year};

    my @lines;
    my $tz = $args{time_zone} // $ENV{TZ} // "UTC";
    my $dt  = DateTime->new(year=>$y, month=>$m, day=>1, time_zone=>$tz);
    my $dtl = DateTime->last_day_of_month(year=>$y, month=>$m, time_zone=>$tz);
    my $dt_today = DateTime->today(time_zone=>$tz);
    my $hol = list_idn_holidays(
        detail => 1, year => $y, month => $m,
        (is_joint_leave => 0) x !$args{show_joint_leave},
    )->[2];

    # XXX use locale
    if ($args{show_year_in_title} // 1) {
        push @lines, _center(21, sprintf("%s %d", $month_names->[$m-1], $y));
    } else {
        push @lines, _center(21, sprintf("%s", $month_names->[$m-1]));
    }

    push @lines, "Sn Sl Rb Km Jm Sb Mg"; # XXX use locale (but TBH locale's versions suck: Se Se Ra Ka Ju Sa Mi)

    my $dow = $dt->day_of_week;
    $dt->subtract(days => $dow-1);
    for my $i (1..$dow-1) {
        push @lines, "" if $i == 1;
        if ($args{show_prev_month_days} // 1) {
            $lines[-1] .= colored(sprintf("%2d ", $dt->day), "bright_black");
        } else {
            $lines[-1] .= "   ";
        }
        $dt->add(days => 1);
    }
    for (1..$dtl->day) {
        if ($dt->day_of_week == 1) {
            push @lines, "";
        }
        my $col = "white";
        if (($args{highlight_today}//1) && DateTime->compare($dt, $dt_today) == 0) {
            $col = "reverse";
        } else {
            for (@$hol) {
                if ($dt->day == $_->{day}) {
                    $col = "bright_red";
                }
            }
        }
        $lines[-1] .= colored(sprintf("%2d ", $dt->day), $col);
        $dt->add(days => 1);
    }
    if ($args{show_next_month_days} // 1) {
        $dow = $dt->day_of_week - 1; $dow = 7 if $dow == 0;
        for my $i ($dow+1..7) {
            $lines[-1] .= colored(sprintf("%2d ", $dt->day), "bright_black");
            $dt->add(days => 1);
        }
    }

    return [\@lines, $hol];
}

$SPEC{gen_calendar} = {
    v => 1.1,
    summary => 'Generate one or more monthly calendars in 3-column format',
    args => {
        months => {
            schema => ['int*', min=>1, max=>12, default=>1],
        },
        year => {
            schema => ['int*'],
            req => 1,
        },
        month => {
            summary => 'The first month',
            schema => ['int*'],
            description => <<'_',

Not required if months=12 (generate whole year from month 1 to 12).

_
        },
        show_holiday_list => {
            schema => ['bool', default => 1],
        },
        show_joint_leave => {
            schema => ['bool', default => 0],
        },
        highlight_today => {
            schema => [bool => default => 1],
        },
        time_zone => {
            schema => 'str*',
        },
    },
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub gen_calendar {
    my %args = @_;
    my $y  = $args{year};
    my $m  = $args{month};
    my $mm = $args{months} // 1;
    my $tz = $args{time_zone} // $ENV{TZ} // "UTC";

    my @lines;

    my %margs = (
        highlight_today => ($args{highlight_today} // 1),
        show_joint_leave => $args{show_joint_leave},
    );

    if ($mm == 12 && !$m) {
        $m = 1;
        $margs{show_year_in_title} = 0;
        push @lines, _center(64, $y);
    }
    $m or return [400, "Please specify month"];
    if ($mm > 1) {
        $margs{show_prev_month_days} = 0;
        $margs{show_next_month_days} = 0;
    }

    my @moncals;
    my $dt = DateTime->new(year=>$y, month=>$m, day=>1, time_zone=>$tz);
    for (1..$mm) {
        push @moncals, gen_monthly_calendar(
            month=>$dt->month, year=>$dt->year, time_zone=>$tz, %margs);
        $dt->add(months => 1);
    }
    my @hol = map {@{ $_->[1] }} @moncals;
    my $l = max(map {~~@$_} map {$_->[0]} @moncals);
    my $i = 0;
    my $j = @moncals;
    while (1) {
        for (0..$l-1) {
            push @lines,
                sprintf("%s %s %s",
                        _rpad(21, $moncals[$i+0][0][$_]//""),
                        _rpad(21, $moncals[$i+1][0][$_]//""),
                        _rpad(21, $moncals[$i+2][0][$_]//""));
        }
        last if $i+3 >= $j;
        $i += 3;
        push @lines, "";
    }

    if ($args{show_holiday_list} // 1) {
        for my $i (0..@hol-1) {
            push @lines, "" if $i == 0;
            push @lines, sprintf("%2d %s = %s", $hol[$i]{day}, $short_month_names->[$hol[$i]{month}-1], $hol[$i]{ind_name});
        }
    }

    [200, "OK", join("\n", @lines)];
}

1;
# ABSTRACT: Display Indonesian calendar on the command-line

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cal::idn - Display Indonesian calendar on the command-line

=head1 VERSION

This document describes version 0.136 of App::cal::idn (from Perl distribution App-cal-idn), released on 2021-05-03.

=head1 SYNOPSIS

 # See cal-idn script provided in this distribution

=head1 DESCRIPTION

This module provides the L<cal-idn> command to display Indonesian calendar on
the command-line.

=head1 FUNCTIONS


=head2 gen_calendar

Usage:

 gen_calendar(%args) -> [status, msg, payload, meta]

Generate one or more monthly calendars in 3-column format.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<highlight_today> => I<bool> (default: 1)

=item * B<month> => I<int>

The first month.

Not required if months=12 (generate whole year from month 1 to 12).

=item * B<months> => I<int> (default: 1)

=item * B<show_holiday_list> => I<bool> (default: 1)

=item * B<show_joint_leave> => I<bool> (default: 0)

=item * B<time_zone> => I<str>

=item * B<year>* => I<int>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 gen_monthly_calendar

Usage:

 gen_monthly_calendar(%args) -> any

Generate a single month calendar.

Return [\@lines, \@hol]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<highlight_today> => I<bool> (default: 1)

=item * B<month>* => I<int>

=item * B<show_holiday_list> => I<bool> (default: 1)

=item * B<show_joint_leave> => I<bool> (default: 0)

=item * B<show_next_month_days> => I<bool> (default: 1)

=item * B<show_prev_month_days> => I<bool> (default: 1)

=item * B<show_year_in_title> => I<bool> (default: 1)

=item * B<time_zone> => I<str>

=item * B<year>* => I<int>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cal-idn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cal-idn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-cal-idn/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
