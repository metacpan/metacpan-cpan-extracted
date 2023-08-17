package App::calx;

use 5.010001;
use strict;
use warnings;

use Color::ANSI::Util qw(ansifg);
use Color::RGB::Util qw(assign_rgb_light_color);
use DateTime;
use List::Util qw(max);
use Text::ANSI::Util qw(ta_length);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-22'; # DATE
our $DIST = 'App-calx'; # DIST
our $VERSION = '0.007'; # VERSION

# XXX use locale
my $month_names = [qw(January February March April May June July August September October November December)];
my $short_month_names = [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)];

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Display a calendar',
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
        highlight_today => {
            schema => [bool => default => 1],
        },
        time_zone => {
            schema => 'str*',
        },
        dates => {
            schema => ['array*', of=>'hash*'],
        },
        caldates_modules => {
            schema => ['array*', of=>'perl::calendar::dates::modname*'],
            cmdline_aliases => {c=>{}},
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

    my $hol = [];
    if ($args{dates} && @{ $args{dates} }) {
        $hol = $args{dates};
    } else {
        for my $mod0 (@{ $args{caldates_modules} // [] }) {
            my $mod = $mod0; $mod =~ s!/!::!g;
            $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            my $res; eval { $res = $mod->get_entries($y, $m) }; next if $@;
            for (@$res) { $_->{module} = $mod0 }
            push @$hol, @$res;
        }
    }
    $hol = [sort {$a->{date} cmp $b->{date}} @$hol];

    # XXX use locale
    if ($args{show_year_in_title} // 1) {
        push @lines, _center(21, sprintf("%s %d", $month_names->[$m-1], $y));
    } else {
        push @lines, _center(21, sprintf("%s", $month_names->[$m-1]));
    }

    push @lines, "Mo Tu We Th Fr Sa Su"; # XXX use locale, option to start on Sunday

    my $dow = $dt->day_of_week;
    $dt->subtract(days => $dow-1);
    for my $i (1..$dow-1) {
        push @lines, "" if $i == 1;
        if ($args{show_prev_month_days} // 1) {
            $lines[-1] .= sprintf("%s%2d \e[0m", ansifg("404040"), $dt->day);
        } else {
            $lines[-1] .= "   ";
        }
        $dt->add(days => 1);
    }
    for (1..$dtl->day) {
        if ($dt->day_of_week == 1) {
            push @lines, "";
        }
        my $col = "808080";
        my $reverse;
        if (($args{highlight_today}//1) && DateTime->compare($dt, $dt_today) == 0) {
            $reverse++;
        } else {
            for (@$hol) {
                if ($dt->day == $_->{day}) {
                    #my $is_holiday = $_->{is_holiday} ||
                    #    (grep {$_ eq 'holiday'} @{ $_->{tags} // [] });
                    $col = assign_rgb_light_color($_->{module} // "dates");
                    $reverse++ if $args{dates};
                }
            }
        }
        $lines[-1] .= sprintf("%s%s%2d \e[0m", $reverse ? "\e[7m" : "", ansifg($col), $dt->day);
        $dt->add(days => 1);
    }
    if ($args{show_next_month_days} // 1) {
        $dow = $dt->day_of_week - 1; $dow = 7 if $dow == 0;
        for my $i ($dow+1..7) {
            $lines[-1] .= sprintf("%s%2d \e[0m", ansifg("404040"), $dt->day);
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
        },
        month => {
            summary => 'The first month',
            schema => ['int*'],
            description => <<'_',

Not required if months=12 (generate whole year from month 1 to 12).

_
        },
        highlight_today => {
            schema => [bool => default => 1],
        },
        time_zone => {
            schema => 'str*',
        },

        dates => {
            schema => ['array*', of=>'hash*'],
        },
        caldates_modules => {
            schema => ['array*', of=>['perl::calendar::dates::modname*']],
        },

    },
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
    args_rels => {
        choose_one => [qw/dates caldates_modules/],
        req_one => [qw/year dates/],
    },
};
sub gen_calendar {
    my %args = @_;
    my $dates = $args{dates};

    my @lines;
    my $tz = $args{time_zone} // $ENV{TZ} // "UTC";

    my @years;
    my ($start_month, $end_month);
    if ($dates && @$dates) {
        my ($min_date, $max_date);
        for (@$dates) {
            $min_date = $_->{date} if !defined($min_date) || $_->{date} lt $min_date;
            $max_date = $_->{date} if !defined($max_date) || $_->{date} gt $max_date;
        }
        my ($min_year, $min_mon, $min_day) = $min_date =~ /(\d{4})-(\d{2})-(\d{2})/;
        my ($max_year, $max_mon, $max_day) = $max_date =~ /(\d{4})-(\d{2})-(\d{2})/;
        if ($min_year < 1582) { die "Minimum year must be 1582\n" }
        if ($max_year > 9999) { die "Minimum year must be 9999\n" }
        @years = $min_year .. $max_year;
        $start_month = $min_mon;
        $end_month = $max_mon;
    } else {
        @years = ($args{year});
        $start_month = $args{month} // 1;
        $end_month = $start_month + ($args{months} // 1) - 1;
    }

    for my $year (@years) {
        my $start_mon2 = $year == $years[0] ? $start_month : 1;
        my $end_mon2 = $year == $years[-1] ? $end_month : 12;

        unless ($start_mon2 == $end_mon2) {
            # show multiples of 3 months instead of just 2 months
            if (($start_mon2-1) % 3) {
                $start_mon2 = int(($start_mon2-1)/3)*3+1;
            }
            if ($end_mon2 % 3) {
                $end_mon2 = int(($end_mon2+2)/3)*3;
            }
        }

        my $year_has_been_printed;
        my @moncals;
        for my $mon ($start_mon2 .. $end_mon2) {
            my %margs = (
                caldates_modules => $args{caldates_modules},
                highlight_today => ($args{highlight_today} // 1),
            );
            if ($start_mon2 == 1 && $end_mon2 == 12) {
                $margs{show_year_in_title} = 0;
                push @lines, _center(64, $year) unless $year_has_been_printed++;
            }
            $margs{show_prev_month_days} = 0 unless $start_mon2 == $end_mon2;
            $margs{show_next_month_days} = 0 unless $start_mon2 == $end_mon2;

            if ($dates) {
                $margs{dates} = [
                    grep { $_->{month} == $mon && $_->{year} == $year }
                    @$dates];
            }

            push @moncals, gen_monthly_calendar(
                month=>$mon, year=>$year, time_zone=>$tz, %margs);
        } # for month

        # group per three months
        my @hol = map {@{ $_->[1] }} @moncals;
        my $l = max(map {@$_+0} map {$_->[0]} @moncals);
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

        # print legends
        for my $i (0..@hol-1) {
            if ($hol[1]{module}) {
                my @notes = ($hol[$i]{module});
                push @notes, @{$hol[$i]{tags}} if $hol[1]{tags};
                push @lines, "" if $i == 0;
                push @lines, sprintf("%s%2d %s = %s\e[0m",
                                     ansifg(assign_rgb_light_color($hol[$i]{module})),
                                     $hol[$i]{day}, $short_month_names->[$hol[$i]{month}-1],
                                     "$hol[$i]{summary} (".join(", ", @notes).")",
                                 );
            }
        }

    } # for year

    [200, "OK", join("\n", @lines)];
}

1;
# ABSTRACT: Display a calendar

__END__

=pod

=encoding UTF-8

=head1 NAME

App::calx - Display a calendar

=head1 VERSION

This document describes version 0.007 of App::calx (from Perl distribution App-calx), released on 2023-06-22.

=head1 SYNOPSIS

 # See calx script provided in this distribution

=head1 DESCRIPTION

This module provides the B<calx> which, like the Unix utility B<cal>, displays
calendar on the command-line. The difference is, B<calx> can also show and
highlight dates from one or more L<Calendar::Dates> modules.

=head1 FUNCTIONS


=head2 gen_calendar

Usage:

 gen_calendar(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate one or more monthly calendars in 3-column format.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<caldates_modules> => I<array[perl::calendar::dates::modname]>

(No description)

=item * B<dates> => I<array[hash]>

(No description)

=item * B<highlight_today> => I<bool> (default: 1)

(No description)

=item * B<month> => I<int>

The first month.

Not required if months=12 (generate whole year from month 1 to 12).

=item * B<months> => I<int> (default: 1)

(No description)

=item * B<time_zone> => I<str>

(No description)

=item * B<year> => I<int>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 gen_monthly_calendar

Usage:

 gen_monthly_calendar(%args) -> any

Generate a single month calendar.

Return [\@lines, \@hol]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<caldates_modules> => I<array[perl::calendar::dates::modname]>

(No description)

=item * B<dates> => I<array[hash]>

(No description)

=item * B<highlight_today> => I<bool> (default: 1)

(No description)

=item * B<month>* => I<int>

(No description)

=item * B<show_next_month_days> => I<bool> (default: 1)

(No description)

=item * B<show_prev_month_days> => I<bool> (default: 1)

(No description)

=item * B<show_year_in_title> => I<bool> (default: 1)

(No description)

=item * B<time_zone> => I<str>

(No description)

=item * B<year>* => I<int>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-calx>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-calx>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-calx>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
