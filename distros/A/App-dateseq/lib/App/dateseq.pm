package App::dateseq;

use 5.010001;
use strict;
use warnings;

use Scalar::Util qw(blessed);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-09'; # DATE
our $DIST = 'App-dateseq'; # DIST
our $VERSION = '0.110'; # VERSION

our %SPEC;

$SPEC{dateseq} = {
    v => 1.1,
    summary => 'Generate a sequence of dates',
    description => <<'_',

This utility is similar to Unix <prog:seq> command, except that it generates a
sequence of dates.

_
    args_rels => {
        'choose_one&' => [
            [qw/business business6/],
        ],
    },
    args => {
        from => {
            summary => 'Starting date',
            schema => ['date*', {
                'x.perl.coerce_to' => 'DateTime',
                'x.perl.coerce_rules' => ['From_str::natural'],
            }],
            pos => 0,
        },
        to => {
            summary => 'End date, if not specified will generate an infinite* stream of dates',
            schema => ['date*', {
                'x.perl.coerce_to' => 'DateTime',
                'x.perl.coerce_rules' => ['From_str::natural'],
            }],
            pos => 1,
        },
        increment => {
            schema => ['duration*', {
                'x.perl.coerce_to' => 'DateTime::Duration',
            }],
            cmdline_aliases => {i=>{}},
            pos => 2,
        },
        reverse => {
            summary => 'Decrement instead of increment',
            schema => 'true*',
            cmdline_aliases => {r=>{}},
        },
        business => {
            summary => 'Only list business days (Mon-Fri), '.
                'or non-business days',
            schema => ['bool*'],
            tags => ['category:filtering'],
        },

        include_dow => {
            summary => 'Only show dates with these day-of-weeks',
            schema => 'date::dow_nums*',
            tags => ['category:filtering'],
        },
        exclude_dow => {
            summary => 'Do not show dates with these day-of-weeks',
            schema => 'date::dow_nums*',
            tags => ['category:filtering'],
        },

        include_month => {
            summary => 'Only show dates with these month numbers',
            schema => 'date::month_nums*',
            tags => ['category:filtering'],
        },
        exclude_month => {
            summary => 'Do not show dates with these month numbers',
            schema => 'date::month_nums*',
            tags => ['category:filtering'],
        },

        business6 => {
            summary => 'Only list business days (Mon-Sat), '.
                'or non-business days',
            schema => ['bool*'],
            tags => ['category:filtering'],
        },
        header => {
            summary => 'Add a header row',
            schema => 'str*',
        },
        limit => {
            summary => 'Only generate a certain amount of dates',
            schema => ['posint*'],
            cmdline_aliases => {n=>{}},
        },
        random => {
            summary => 'Instead of incrementing/decrementing monotonically, generate random date between --to and --from',
            schema => ['true*'],
            description => <<'_',

If you specify this, you have to specify `--to` *and* `--from`.

Also, currently, if you also specify `--limit-yearly` or `--limit-monthly`, the
script may hang because it runs out of dates, so be careful when specifying
these options combined.

_
        },
        limit_yearly => {
            summary => 'Only output at most this number of dates for each year',
            schema => ['posint*'],
        },
        limit_monthly => {
            summary => 'Only output at most this number of dates for each month',
            schema => ['posint*'],
        },
        # XXX limit_weekly, limit_daily, limit_hourly, limit_minutely, limit_secondly
        strftime => {
            summary => 'strftime() format for each date',
            description => <<'_',

Default is `%Y-%m-%d`, unless when hour/minute/second is specified, then it is
`%Y-%m-%dT%H:%M:%S`.

`dateseq` actually uses <pm:DateTimeX::strftimeq>, so you can embed Perl code
for flexibility. For example:

    % dateseq 2019-11-19 2019-11-25 -f '%Y-%m-%d%( $_->day_of_week == 7 ? "su" : "" )q'

will print something like:

    2019-11-19
    2019-11-20
    2019-11-21
    2019-11-22
    2019-11-23
    2019-11-24su
    2019-11-25

_
            schema => ['str*'],
            cmdline_aliases => {f=>{}},
            tags => ['category:formatting'],
        },
        format_class => {
            summary => 'Use a DateTime::Format::* class for formatting',
            schema => ['perl::modname'],
            tags => ['category:formatting'],
            completion => sub {
                require Complete::Module;
                my %args = @_;
                Complete::Module::complete_module(
                    word => $args{word}, ns_prefix => 'DateTime::Format');
            },
            description => <<'_',

By default, <pm:DateTime::Format::Strptime> is used with pattern set from the
<strftime> option.

_
        },
        format_class_attrs => {
            summary => 'Arguments to pass to constructor of DateTime::Format::* class',
            schema => ['hash'],
            tags => ['category:formatting'],
        },
        eval => {
            summary => 'Run perl code for each date',
            schema => 'str*',
            tags => ['category:output'],
            cmdline_aliases => {e=>{}},
            description => <<'_',

Specified perl code will receive the date as DateTime object in `$_`and expected
to return result to print.

_
        },
    },
    examples => [
        {
            summary => 'Generate "infinite" dates from today',
            src => '[[prog]]',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate dates from 2015-01-01 to 2015-01-31',
            src => '[[prog]] 2015-01-01 2015-01-31',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate dates from yesterday to 2 weeks from now',
            src => '[[prog]] yesterday "2 weeks from now"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate dates from 2015-01-31 to 2015-01-01 (reverse)',
            src => '[[prog]] 2015-01-31 2015-01-01 -r',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate "infinite" dates from 2015-01-01 (reverse)',
            src => '[[prog]] 2015-01-01 -r',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate 10 dates from 2015-01-01',
            src => '[[prog]] 2015-01-01 -n 10',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate dates with increment of 3 days',
            src => '[[prog]] 2015-01-01 2015-01-31 -i P3D',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate first 20 business days (Mon-Fri) after 2015-01-01',
            src => '[[prog]] 2015-01-01 --business -n 20 -f "%Y-%m-%d(%a)"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'Generate first 5 non-business days (Sat-Sun) after 2015-01-01',
            src => '[[prog]] 2015-01-01 --no-business -n 5',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Show the first business day (Mon-Fri) of each month in 2021',
            src => '[[prog]] 2021-01-01 2021-12-13 --business --limit-monthly 1 -f "%Y-%m-%d(%a)"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'Show the last business day (Mon-Fri) of each month in 2021',
            src => '[[prog]] 2021-12-31 2021-01-01 -r --business --limit-monthly 1 -f "%Y-%m-%d(%a)"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'Show Mondays, Wednesdays, and Fridays between 2015-01-01 and 2015-02-28',
            src => '[[prog]] 2015-01-01 2015-02-28 --include-dow Mo,We,Fr -f "%Y-%m-%d(%a)"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
            'x.doc.show_result' => 0, # temp, coerce fail
        },
        {
            summary => 'Show dates (except Mondays) after 2015-01-01 and 2015-02-28',
            src => '[[prog]] 2015-01-01 2015-02-28 --exclude-dow Mo -f "%Y-%m-%d(%a)"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
            'x.doc.show_result' => 0, # temp, coerce fail
        },
        {
            summary => 'Generate a CSV data',
            src => '[[prog]] 2010-01-01 2015-01-31 -f "%Y,%m,%d" --header "year,month,day"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate periods (YYYY-MM)',
            src => '[[prog]] 2010-01-01 2015-12-31 -i P1M -f "%Y-%m"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'List non-holidays in 2015 (using Indonesian holidays)',
            description => <<'_',

See also <prog:dateseq-id> as alternative.

_
            src => 'setop --diff <([[prog]] 2015-01-01 2015-12-31) <(list-idn-holidays --year 2015)',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List non-holidays business days in 2015 (using Indonesian holidays)',
            description => <<'_',

See also <prog:dateseq-id> as alternative.

_
            src => 'setop --diff <([[prog]] 2015-01-01 2015-12-31 --business) <(list-idn-holidays --year 2015)',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'Use with fsql',
            src => q{[[prog]] 2010-01-01 2015-12-01 -f "%Y,%m" -i P1M --header "year,month" | fsql --add-csv - --add-csv data.csv -F YEAR -F MONTH 'SELECT year, month, data1 FROM stdin WHERE YEAR(data.date)=year AND MONTH(data.date)=month'},
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Use %q (see DateTimeX::strftimeq)',
            src => q{[[prog]] 2020-12-24 2021-01-15 -f '%Y-%m-%d%( $_->day_of_week == 7 ? "su" : "" )q'},
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'Print first and last days of each month of 2021',
            src => q{[[prog]] 2021-01-01 2021-12-01 --increment '1 month' -e 'my $dt2 = $_->clone; $dt2->add(months=>1); $dt2->add(days => -1); $_->ymd . " " . $dt2->ymd'},
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'Retrieve MetaCPAN releases data for 2020, saved in monthly JSON files',
            src => q{[[prog]] 2020-01-01 2020-12-01 --increment '1 month' -e 'my $dt2 = $_->clone; $dt2->add(months=>1); $dt2->add(days => -1); sprintf "list-metacpan-releases --from-date %sT00:00:00 --to-date %sT23:59:59 --json > %04d%02d.json", $_->ymd, $dt2->ymd, $_->year, $_->month' | bash},
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate 100 random dates between a certain range',
            src => q{[[prog]] --random --from "1 year ago" --to "1 year from now" --limit 100},
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
    ],
    links => [
        {url=>'prog:durseq', summary=>'Produce sequence of date durations'},
        {url=>'prog:dateseq-id', summary=>'A wrapper for dateseq, with built-in support for Indonesian holidays'},
        {url=>'prog:seq'},
        {url=>'prog:seq-pl', summary=>'Perl variant of seq'},
    ],
};
sub dateseq {
    require DateTime::Duration;
    require DateTime::Format::Strftimeq;

    my %args = @_;

    $args{from} //= DateTime->today;
    $args{increment} //= DateTime::Duration->new(days=>1);
    my $reverse = $args{reverse};

    my $random = $args{random};
    return [412, "If you specify --random, you must also specify --from *and* --to"]
        if $random && !$args{to};

    my $formatter;
    if (my $cl = $args{format_class}) {
        $cl = "DateTime::Format::$cl";
        (my $cl_pm = "$cl.pm") =~ s!::!/!g;
        require $cl_pm;
        my $attrs = $args{format_class_attrs} // {};
        $formatter = $cl->new(%$attrs);
    } else {
        my $strftime  = $args{strftime} // do {
            my $has_hms;
            {
                if ($args{from}->hour || $args{from}->minute || $args{from}->second) {
                    $has_hms++; last;
                }
                if (defined($args{to}) &&
                        ($args{to}->hour || $args{to}->minute || $args{to}->second)) {
                    $has_hms++; last;
                }
                if ($args{increment}->hours || $args{increment}->minutes || $args{increment}->seconds) {
                    $has_hms++; last;
                }
            }
            $has_hms ? '%Y-%m-%dT%H:%M:%S' : '%Y-%m-%d';
        };
        $formatter = DateTime::Format::Strftimeq->new(
            format => $strftime,
        );
    }

    my %seen_years;  # key=year (e.g. 2021), val=int
    my %seen_months; # key=year-mon (e.g. 2021-01), val=int
    my $num_dates = 0;
    my $code_filter = sub {
        my $dt = shift;
        if (defined $args{business}) {
            my $dow = $dt->day_of_week;
            if ($args{business}) {
                return 0 if $dow >= 6;
            } else {
                return 0 if $dow <  6;
            }
        }
        if (defined $args{business6}) {
            my $dow = $dt->day_of_week;
            if ($args{business6}) {
                return 0 if $dow >= 7;
            } else {
                return 0 if $dow <  7;
            }
        }
        if (defined $args{include_dow}) {
            my $dt_dow = $dt->day_of_week;
            return 0 unless grep { $dt_dow == $_ } @{ $args{include_dow} };
        }
        if (defined $args{exclude_dow}) {
            my $dt_dow = $dt->day_of_week;
            return 0 if     grep { $dt_dow == $_ } @{ $args{exclude_dow} };
        }
        if (defined $args{include_month}) {
            my $dt_mon = $dt->month;
            return 0 unless grep { $dt_mon == $_ } @{ $args{include_month} };
        }
        if (defined $args{exclude_dow}) {
            my $dt_mon = $dt->month;
            return 0 if     grep { $dt_mon == $_ } @{ $args{exclude_month} };
        }

        if ($args{_filter}) {
            return 0 unless $args{_filter}->($dt, \%args);
        }

        if ($args{limit_yearly}) {
            my $key = $dt->year;
            return 0 if ++$seen_years{$key} > $args{limit_yearly};
        }
        if ($args{limit_monthly}) {
            my $key = $dt->strftime("%Y-%m");
            return 0 if ++$seen_months{$key} > $args{limit_monthly};
        }

        1;
    };

    my $_eval_code;
    if ($args{eval}) {
        $_eval_code = eval "package main; sub { no strict; no warnings; $args{eval} }"; ## no critic: BuiltinFunctions::ProhibitStringyEval
        die "Can't compile Perl code '$args{eval}': $@" if $@;
    }

    my $_format = sub {
        my $dt = shift;
        if ($_eval_code) {
            my $res;
            {
                local $_ = $dt;
                $res = $_eval_code->();
                $res = $_ unless $res;
                $res = $formatter->format_datetime($res) if blessed($res);
            }
            $res;
        } else {
            $formatter->format_datetime($dt);
        }
    };

    my $num_secs;
    if ($random) {
        my $epoch_from = $args{from}->epoch;
        my $epoch_to   = $args{to}->epoch;
        $num_secs = $epoch_to-$epoch_from;
    }

    if ((defined $args{to} || defined $args{limit}) && !$random) {
        my @res;
        push @res, $args{header} if defined $args{header};
        my $dt = $args{from}->clone;
        while (1) {
            last if defined($args{limit}) && $num_dates >= $args{limit};
            #say "D:$dt vs $args{to}? ", DateTime->compare($dt, $args{to});
            if (defined $args{to}) {
                last if !$reverse && DateTime->compare($dt, $args{to}) > 0;
                last if  $reverse && DateTime->compare($dt, $args{to}) < 0;
            }
            if ($code_filter->($dt)) {
                push @res, $_format->($dt);
                $num_dates++;
            }
            $dt = $reverse ? $dt - $args{increment} : $dt + $args{increment};
        }
        return [200, "OK", \@res];
    } else {
        # stream
        # --random always goes here
        my $dt = $args{from}->clone;
        my $has_printed_header;
        my $func = sub {
            return $args{header} if defined $args{header} && !$has_printed_header++;
            return if defined $args{limit} && $num_dates++ >= $args{limit};
          REPEAT:
            if ($random) {
                $dt = $args{from}->clone->add(seconds => $num_secs * rand());
            }
            goto REPEAT unless $code_filter->($dt);
            my $res = $_format->($dt);

            if ($random) {
            } else {
                $dt = $reverse ?
                    $dt - $args{increment} : $dt + $args{increment};
            }
            $res;
        };
        return [200, "OK", $func, {schema=>'str*', stream=>1}];
    }
}

1;
# ABSTRACT: Generate a sequence of dates

__END__

=pod

=encoding UTF-8

=head1 NAME

App::dateseq - Generate a sequence of dates

=head1 VERSION

This document describes version 0.110 of App::dateseq (from Perl distribution App-dateseq), released on 2022-09-09.

=head1 FUNCTIONS


=head2 dateseq

Usage:

 dateseq(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate a sequence of dates.

This utility is similar to Unix L<seq> command, except that it generates a
sequence of dates.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<business> => I<bool>

Only list business days (Mon-Fri), or non-business days.

=item * B<business6> => I<bool>

Only list business days (Mon-Sat), or non-business days.

=item * B<eval> => I<str>

Run perl code for each date.

Specified perl code will receive the date as DateTime object in C<$_>and expected
to return result to print.

=item * B<exclude_dow> => I<date::dow_nums>

Do not show dates with these day-of-weeks.

=item * B<exclude_month> => I<date::month_nums>

Do not show dates with these month numbers.

=item * B<format_class> => I<perl::modname>

Use a DateTime::Format::* class for formatting.

By default, L<DateTime::Format::Strptime> is used with pattern set from the
<strftime> option.

=item * B<format_class_attrs> => I<hash>

Arguments to pass to constructor of DateTime::Format::* class.

=item * B<from> => I<date>

Starting date.

=item * B<header> => I<str>

Add a header row.

=item * B<include_dow> => I<date::dow_nums>

Only show dates with these day-of-weeks.

=item * B<include_month> => I<date::month_nums>

Only show dates with these month numbers.

=item * B<increment> => I<duration>

=item * B<limit> => I<posint>

Only generate a certain amount of dates.

=item * B<limit_monthly> => I<posint>

Only output at most this number of dates for each month.

=item * B<limit_yearly> => I<posint>

Only output at most this number of dates for each year.

=item * B<random> => I<true>

Instead of incrementingE<sol>decrementing monotonically, generate random date between --to and --from.

If you specify this, you have to specify C<--to> I<and> C<--from>.

Also, currently, if you also specify C<--limit-yearly> or C<--limit-monthly>, the
script may hang because it runs out of dates, so be careful when specifying
these options combined.

=item * B<reverse> => I<true>

Decrement instead of increment.

=item * B<strftime> => I<str>

strftime() format for each date.

Default is C<%Y-%m-%d>, unless when hour/minute/second is specified, then it is
C<%Y-%m-%dT%H:%M:%S>.

C<dateseq> actually uses L<DateTimeX::strftimeq>, so you can embed Perl code
for flexibility. For example:

 % dateseq 2019-11-19 2019-11-25 -f '%Y-%m-%d%( $_->day_of_week == 7 ? "su" : "" )q'

will print something like:

 2019-11-19
 2019-11-20
 2019-11-21
 2019-11-22
 2019-11-23
 2019-11-24su
 2019-11-25

=item * B<to> => I<date>

End date, if not specified will generate an infinite* stream of dates.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-dateseq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-dateseq>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-dateseq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
