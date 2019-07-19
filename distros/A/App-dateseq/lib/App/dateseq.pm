package App::dateseq;

our $DATE = '2019-07-16'; # DATE
our $VERSION = '0.096'; # VERSION

use 5.010001;
use strict;
use warnings;

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
                'x.perl.coerce_rules' => ['str_natural'],
            }],
            pos => 0,
        },
        to => {
            summary => 'End date, if not specified will generate an infinite* stream of dates',
            schema => ['date*', {
                'x.perl.coerce_to' => 'DateTime',
                'x.perl.coerce_rules' => ['str_natural'],
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
            summary => 'Only generate a certain amount of numbers',
            schema => ['int*', min=>1],
            cmdline_aliases => {n=>{}},
        },
        date_format => {
            summary => 'strftime() format for each date',
            description => <<'_',

Default is `%Y-%m-%d`, unless when hour/minute/second is specified, then it is
`%Y-%m-%dT%H:%M:%S`.

_
            schema => ['str*'],
            cmdline_aliases => {f=>{}},
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
            summary => 'Show Mondays, Wednesdays, and Fridays between 2015-01-01 and 2015-02-28',
            src => '[[prog]] 2015-01-01 2015-02-28 --include-dow Mo,We,Fr -f "%Y-%m-%d(%a)"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Show dates (except Mondays) after 2015-01-01 and 2015-02-28',
            src => '[[prog]] 2015-01-01 2015-02-28 --exclude-dow Mo -f "%Y-%m-%d(%a)"',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
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
            src => 'setop --diff <([[prog]] 2015-01-01 2015-12-31) <(list-id-holidays --year 2015)',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List non-holidays business days in 2015 (using Indonesian holidays)',
            src => 'setop --diff <([[prog]] 2015-01-01 2015-12-31 --business) <(list-id-holidays --year 2015)',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'Use with fsql',
            src => q{[[prog]] 2010-01-01 2015-12-01 -f "%Y,%m" -i P1M --header "year,month" | fsql --add-csv - --add-csv data.csv -F YEAR -F MONTH 'SELECT year, month, data1 FROM stdin WHERE YEAR(data.date)=year AND MONTH(data.date)=month'},
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
    ],
    links => [
        {url=>'prog:durseq', summary=>'Produce sequence of date durations'},
        {url=>'prog:seq'},
        {url=>'prog:seq-pl', summary=>'Perl variant of seq'},
    ],
};
sub dateseq {
    require DateTime::Duration;
    require DateTime::Format::Strptime;

    my %args = @_;

    $args{from} //= DateTime->today;
    $args{increment} //= DateTime::Duration->new(days=>1);
    my $reverse = $args{reverse};

    my $fmt  = $args{date_format} // do {
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
    my $strp = DateTime::Format::Strptime->new(
        pattern => $fmt,
    );

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
        1;
    };

    if (defined $args{to} || defined $args{limit}) {
        my @res;
        push @res, $args{header} if $args{header};
        my $dt = $args{from}->clone;
        while (1) {
            #say "D:$dt vs $args{to}? ", DateTime->compare($dt, $args{to});
            if (defined $args{to}) {
                last if !$reverse && DateTime->compare($dt, $args{to}) > 0;
                last if  $reverse && DateTime->compare($dt, $args{to}) < 0;
            }
            push @res, $strp->format_datetime($dt) if $code_filter->($dt);
            last if defined($args{limit}) && @res >= $args{limit};
            $dt = $reverse ? $dt - $args{increment} : $dt + $args{increment};
        }
        return [200, "OK", \@res];
    } else {
        # stream
        my $dt = $args{from}->clone;
        my $j  = $args{header} ? -1 : 0;
        my $next_dt;
        #my $finish;
        my $func0 = sub {
            #return undef if $finish;
            $dt = $next_dt if $j++ > 0;
            return $args{header} if $j == 0 && $args{header};
            $next_dt = $reverse ?
                $dt - $args{increment} : $dt + $args{increment};
            #$finish = 1 if ...
            return $dt;
        };
        my $filtered_func = sub {
            while (1) {
                my $dt = $func0->();
                return undef unless defined $dt;
                last if $code_filter->($dt);
            }
            $strp->format_datetime($dt);
        };
        return [200, "OK", $filtered_func, {schema=>'str*', stream=>1}];
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

This document describes version 0.096 of App::dateseq (from Perl distribution App-dateseq), released on 2019-07-16.

=head1 FUNCTIONS


=head2 dateseq

Usage:

 dateseq(%args) -> [status, msg, payload, meta]

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

=item * B<date_format> => I<str>

strftime() format for each date.

Default is C<%Y-%m-%d>, unless when hour/minute/second is specified, then it is
C<%Y-%m-%dT%H:%M:%S>.

=item * B<exclude_dow> => I<date::dow_nums>

Do not show dates with these day-of-weeks.

=item * B<exclude_month> => I<date::month_nums>

Do not show dates with these month numbers.

=item * B<from> => I<date>

Starting date.

=item * B<header> => I<str>

Add a header row.

=item * B<include_dow> => I<date::dow_nums>

Only show dates with these day-of-weeks.

=item * B<include_month> => I<date::month_nums>

Only show dates with these month numbers.

=item * B<increment> => I<duration>

=item * B<limit> => I<int>

Only generate a certain amount of numbers.

=item * B<reverse> => I<true>

Decrement instead of increment.

=item * B<to> => I<date>

End date, if not specified will generate an infinite* stream of dates.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-dateseq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-dateseq>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-dateseq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<durseq>. Produce sequence of date durations.

L<seq>.

L<seq-pl>. Perl variant of seq.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
