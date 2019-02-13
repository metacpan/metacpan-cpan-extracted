package App::calx;

our $DATE = '2019-02-13'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Color::ANSI::Util qw(ansifg);
use Color::RGB::Util qw(assign_rgb_light_color);
use DateTime;
use List::Util qw(max);
use Text::ANSI::Util qw(ta_length);

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
        caldates_modules => {
            schema => ['array*', of=>'perl::modname*'],
            cmdline_aliases => {c=>{}},
        },
    },
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
    result_naked => 1,
};
sub gen_monthly_calendar {
    my %args = @_; no warnings ('void');require List::Util;my $_sahv_dpath = []; my $arg_err; if (exists($args{'caldates_modules'})) { ((defined($args{'caldates_modules'})) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((ref($args{'caldates_modules'}) eq 'ARRAY') ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type array"),0)) && ([push(@{$_sahv_dpath}, undef), ~~((!defined(List::Util::first(sub {!( ($_sahv_dpath->[-1] = $_), ((defined($args{'caldates_modules'}->[$_])) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && (($args{'caldates_modules'}->[$_] = (1) ? (do { my $tmp = $args{'caldates_modules'}->[$_]; $tmp = $1 if $tmp =~ m!\A(\w+(?:/\w+)*).pm\z!; $tmp =~ s!::?|/|\.|-!::!g; $tmp }) : $args{'caldates_modules'}->[$_]), 1) && ((!ref($args{'caldates_modules'}->[$_])) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)) && (($args{'caldates_modules'}->[$_] =~ qr((?:(?-)\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\z))) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z"),0)) )}, 0..@{$args{'caldates_modules'}}-1))) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Does not satisfy the following schema: each array element must be: (text, must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z)"),0)), pop(@{$_sahv_dpath})]->[1]); if ($arg_err) { die "gen_monthly_calendar(): " . "Invalid argument value for caldates_modules: $arg_err" } }no warnings ('void');if (exists($args{'highlight_today'})) { (($args{'highlight_today'} //= 1), 1) && (!defined($args{'highlight_today'}) ? 1 :  ((!ref($args{'highlight_today'})) ? 1 : (($arg_err //= "Not of type boolean value"),0))); if ($arg_err) { die "gen_monthly_calendar(): " . "Invalid argument value for highlight_today: $arg_err" } } else { $args{'highlight_today'} = 1;}no warnings ('void');require Scalar::Util::Numeric;if (exists($args{'month'})) { ((defined($args{'month'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::Numeric::isint($args{'month'})) ? 1 : (($arg_err //= "Not of type integer"),0)) && (($args{'month'} >= 1 && $args{'month'} <= 12) ? 1 : (($arg_err //= "Must be between 1 and 12"),0)); if ($arg_err) { die "gen_monthly_calendar(): " . "Invalid argument value for month: $arg_err" } }if (!exists($args{'month'})) { die "gen_monthly_calendar(): " . "Missing argument: month" } no warnings ('void');if (exists($args{'show_next_month_days'})) { (($args{'show_next_month_days'} //= 1), 1) && (!defined($args{'show_next_month_days'}) ? 1 :  ((!ref($args{'show_next_month_days'})) ? 1 : (($arg_err //= "Not of type boolean value"),0))); if ($arg_err) { die "gen_monthly_calendar(): " . "Invalid argument value for show_next_month_days: $arg_err" } } else { $args{'show_next_month_days'} = 1;}no warnings ('void');if (exists($args{'show_prev_month_days'})) { (($args{'show_prev_month_days'} //= 1), 1) && (!defined($args{'show_prev_month_days'}) ? 1 :  ((!ref($args{'show_prev_month_days'})) ? 1 : (($arg_err //= "Not of type boolean value"),0))); if ($arg_err) { die "gen_monthly_calendar(): " . "Invalid argument value for show_prev_month_days: $arg_err" } } else { $args{'show_prev_month_days'} = 1;}no warnings ('void');if (exists($args{'show_year_in_title'})) { (($args{'show_year_in_title'} //= 1), 1) && (!defined($args{'show_year_in_title'}) ? 1 :  ((!ref($args{'show_year_in_title'})) ? 1 : (($arg_err //= "Not of type boolean value"),0))); if ($arg_err) { die "gen_monthly_calendar(): " . "Invalid argument value for show_year_in_title: $arg_err" } } else { $args{'show_year_in_title'} = 1;}no warnings ('void');if (exists($args{'time_zone'})) { ((defined($args{'time_zone'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'time_zone'})) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { die "gen_monthly_calendar(): " . "Invalid argument value for time_zone: $arg_err" } }no warnings ('void');if (exists($args{'year'})) { ((defined($args{'year'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::Numeric::isint($args{'year'})) ? 1 : (($arg_err //= "Not of type integer"),0)); if ($arg_err) { die "gen_monthly_calendar(): " . "Invalid argument value for year: $arg_err" } }if (!exists($args{'year'})) { die "gen_monthly_calendar(): " . "Missing argument: year" } # VALIDATE_ARGS
    my $m = $args{month};
    my $y = $args{year};

    my @lines;
    my $tz = $args{time_zone} // $ENV{TZ} // "UTC";
    my $dt  = DateTime->new(year=>$y, month=>$m, day=>1, time_zone=>$tz);
    my $dtl = DateTime->last_day_of_month(year=>$y, month=>$m, time_zone=>$tz);
    my $dt_today = DateTime->today(time_zone=>$tz);

    my $hol = [];
    for my $mod0 (@{ $args{caldates_modules} // [] }) {
        my $mod = $mod0;
        $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $res; eval { $res = $mod->get_entries($y, $m) }; next if $@;
        for (@$res) { $_->{module} = $mod0 }
        push @$hol, @$res;
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
                    my $is_holiday = $_->{is_holiday} ||
                        (grep {$_ eq 'holiday'} @{ $_->{tags} // [] });
                    $col = assign_rgb_light_color($_->{module});
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
            req => 1,
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
    },
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub gen_calendar {
    my %args = @_; no warnings ('void');my $arg_err; if (exists($args{'highlight_today'})) { (($args{'highlight_today'} //= 1), 1) && (!defined($args{'highlight_today'}) ? 1 :  ((!ref($args{'highlight_today'})) ? 1 : (($arg_err //= "Not of type boolean value"),0))); if ($arg_err) { return [400, "Invalid argument value for highlight_today: $arg_err"] } } else { $args{'highlight_today'} = 1;}no warnings ('void');require Scalar::Util::Numeric;if (exists($args{'month'})) { ((defined($args{'month'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::Numeric::isint($args{'month'})) ? 1 : (($arg_err //= "Not of type integer"),0)); if ($arg_err) { return [400, "Invalid argument value for month: $arg_err"] } }no warnings ('void');if (exists($args{'months'})) { (($args{'months'} //= 1), 1) && ((defined($args{'months'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::Numeric::isint($args{'months'})) ? 1 : (($arg_err //= "Not of type integer"),0)) && (($args{'months'} >= 1) ? 1 : (($arg_err //= "Must be at least 1"),0)) && (($args{'months'} <= 12) ? 1 : (($arg_err //= "Must be at most 12"),0)); if ($arg_err) { return [400, "Invalid argument value for months: $arg_err"] } } else { $args{'months'} = 1;}no warnings ('void');if (exists($args{'time_zone'})) { ((defined($args{'time_zone'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'time_zone'})) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for time_zone: $arg_err"] } }no warnings ('void');if (exists($args{'year'})) { ((defined($args{'year'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::Numeric::isint($args{'year'})) ? 1 : (($arg_err //= "Not of type integer"),0)); if ($arg_err) { return [400, "Invalid argument value for year: $arg_err"] } }if (!exists($args{'year'})) { return [400, "Missing argument: year"] } # VALIDATE_ARGS
    my $y  = $args{year};
    my $m  = $args{month};
    my $mm = $args{months} // 1;
    my $tz = $args{time_zone} // $ENV{TZ} // "UTC";

    my @lines;

    my %margs = (
        caldates_modules => $args{caldates_modules},
        highlight_today => ($args{highlight_today} // 1),
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

    for my $i (0..@hol-1) {
        my @notes = ($hol[$i]{module});
        push @notes, @{$hol[$i]{tags}} if $hol[1]{tags};
        push @lines, "" if $i == 0;
        push @lines, sprintf("%s%2d %s = %s\e[0m",
                             ansifg(assign_rgb_light_color($hol[$i]{module})),
                             $hol[$i]{day}, $short_month_names->[$hol[$i]{month}-1],
                             "$hol[$i]{summary} (".join(", ", @notes).")",
                         );
    }

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

This document describes version 0.004 of App::calx (from Perl distribution App-calx), released on 2019-02-13.

=head1 SYNOPSIS

 # See calx script provided in this distribution

=head1 DESCRIPTION

This module provides the B<calx> which, like the Unix utility B<cal>, displays
calendar on the command-line. The difference is, B<calx> can also show and
highlight dates from one or more L<Calendar::Dates> modules.

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

=item * B<caldates_modules> => I<array[perl::modname]>

=item * B<highlight_today> => I<bool> (default: 1)

=item * B<month>* => I<int>

=item * B<show_next_month_days> => I<bool> (default: 1)

=item * B<show_prev_month_days> => I<bool> (default: 1)

=item * B<show_year_in_title> => I<bool> (default: 1)

=item * B<time_zone> => I<str>

=item * B<year>* => I<int>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-calx>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-calx>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-calx>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
