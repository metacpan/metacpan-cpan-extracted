package App::dateseq::idn;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-30'; # DATE
our $DIST = 'App-dateseq-idn'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::dateseq ();
use Perinci::Sub::Util qw(gen_modified_sub);

gen_modified_sub(
    base_name => 'App::dateseq::dateseq',
    output_name => 'dateseq_idn',
    add_args => {
        holiday => {
            summary => 'Only list holidays (or non-holidays)',
            schema => 'bool*',
            tags => ['category:filtering'],
        },
        include_joint_leave => {
            summary => 'Whether to assume joint leave days as holidays',
            schema => 'bool*',
            tags => ['category:filtering'],
            cmdline_aliases => {j=>{}},
        },
    },
    modify_meta => sub {
        my $meta = shift;
        $meta->{summary} = 'Like dateseq, but with built-in support for Indonesian holidays';
        $meta->{description} = <<'_';
This utility is a wrapper for <prog:dateseq>, with builtin support for
Indonesian holidays (data from <pm:Calendar::Indonesia::Holiday>). It offers
additional --holiday (and --noholiday, as well as -j) options to let you filter
dates based on whether they are Indonesian holidays.
_

        $meta->{examples} = [
            {
                summary => 'List Indonesian holidays between 2020-01-01 to 2021-12-31',
                src => '[[prog]] 2020-01-01 2021-12-13 --holiday',
                src_plang => 'bash',
                test => 0,
                'x.doc.show_result' => 0,
            },
            {
                summary => 'List the last non-holiday business day of each month in 2021',
                src => '[[prog]] 2021-12-31 2021-01-01 -r --noholiday -j --business --limit-monthly 1',
                src_plang => 'bash',
                test => 0,
                'x.doc.show_result' => 0,
            },
        ];

        $meta->{links} = [
            {url=>'prog:dateseq'},
        ];
    },
    output_code => sub {
        require Calendar::Indonesia::Holiday;

        my %args = @_;

        my $holiday = delete $args{holiday};
        my $inc_jv  = delete $args{include_joint_leave};
        $args{_filter} = sub {
            my $dt = shift;

            if (defined $holiday) {
                my $date = $dt->ymd;
                my $res = Calendar::Indonesia::Holiday::is_id_holiday(date=>$date, detail=>1);
                unless ($res->[0] == 200) {
                    log_error "Cannot determine if %s is a holiday: %s", $date, $res;
                    return 0;
                }
                my $is_holiday = $res->[2];
                unless (defined $is_holiday) {
                    log_error "Cannot determine if %s is a holiday (2): %s", $date, $res->[3]{'cmdline.result'};
                    return 0;
                }
                $is_holiday = 0 if $is_holiday && $is_holiday->{is_joint_leave} && !$inc_jv;
                return !($is_holiday xor $holiday);
            }

            1;
        };

        App::dateseq::dateseq(%args);
    },
);

1;
# ABSTRACT: Like dateseq, but with built-in support for Indonesian holidays

__END__

=pod

=encoding UTF-8

=head1 NAME

App::dateseq::idn - Like dateseq, but with built-in support for Indonesian holidays

=head1 VERSION

This document describes version 0.003 of App::dateseq::idn (from Perl distribution App-dateseq-idn), released on 2021-01-30.

=head1 FUNCTIONS


=head2 dateseq_idn

Usage:

 dateseq_idn(%args) -> [status, msg, payload, meta]

Like dateseq, but with built-in support for Indonesian holidays.

This utility is a wrapper for L<dateseq>, with builtin support for
Indonesian holidays (data from L<Calendar::Indonesia::Holiday>). It offers
additional --holiday (and --noholiday, as well as -j) options to let you filter
dates based on whether they are Indonesian holidays.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<business> => I<bool>

Only list business days (Mon-Fri), or non-business days.

=item * B<business6> => I<bool>

Only list business days (Mon-Sat), or non-business days.

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

=item * B<holiday> => I<bool>

Only list holidays (or non-holidays).

=item * B<include_dow> => I<date::dow_nums>

Only show dates with these day-of-weeks.

=item * B<include_joint_leave> => I<bool>

Whether to assume joint leave days as holidays.

=item * B<include_month> => I<date::month_nums>

Only show dates with these month numbers.

=item * B<increment> => I<duration>

=item * B<limit> => I<posint>

Only generate a certain amount of numbers.

=item * B<limit_monthly> => I<posint>

Only output at most this number of dates for each month.

=item * B<limit_yearly> => I<posint>

Only output at most this number of dates for each year.

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-dateseq-idn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-dateseq-idn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-dateseq-idn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::dateseq>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
