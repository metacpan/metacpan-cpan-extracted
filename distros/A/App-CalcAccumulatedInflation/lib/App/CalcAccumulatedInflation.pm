package App::CalcAccumulatedInflation;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-17'; # DATE
our $DIST = 'App-CalcAccumulatedInflation'; # DIST
our $VERSION = '0.052'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{calc_accumulated_inflation} = {
    v => 1.1,
    summary => 'Calculate accumulated inflation (or savings rate, etc) over the years',
    description => <<'_',

This routine generates a table of accumulated inflation over a period of several
years. You can either specify a fixed rate for every years (`yearly_rate`), or
specify each year's rates (`rates`). You can also optionally set base index
(default to 1) and base year (default to 0).

_
    args => {
        years => {
            schema => ['int*', min=>0],
            default => 10,
        },
        rates => {
            summary => 'Different rates for each year, in percent',
            schema  => ['array*', of=>'float*', min_len=>1, 'x.perl.coerce_rules'=>['From_str::comma_sep']],
        },
        yearly_rate => {
            summary => 'A single rate for every year, in percent',
            schema => 'float*',
            cmdline_aliases => {y=>{}},
        },
        base_index => {
            schema => 'float*',
            default => 1,
        },
        base_year => {
            schema => 'float*',
            default => 0,
        },
    },
    args_rels => {
        req_one => ['rates', 'yearly_rate'],
    },
    examples => [
        {
            summary => 'See accumulated 6%/year inflation for 10 years',
            args => {yearly_rate=>6},
        },
        {
            summary => 'See accumulated 5.5%/year inflation for 7 years',
            args => {yearly_rate=>5.5, years=>7},
        },
        {
            summary => "Indonesia's inflation rate for 2003-2014",
            args => {rates=>[5.16, 6.40, 17.11, # 2003-2005
                             6.60, 6.59, 11.06, 2.78, 6.96, # 2006-2010
                             3.79, 4.30, 8.38, 8.36, # 2011-2014
                         ]},
        },
        {
            summary => 'How much will your $100,000 grow over the next 10 years, if the savings rate is 4%; assuming this year is 2021',
            args => {yearly_rate=>4, years=>10, base_year=>2021, base_index=>100000},
        },
    ],
    result_naked => 1,
};
sub calc_accumulated_inflation {
    my %args = @_;

    my $index = $args{base_index} // 1;
    my $year = $args{base_year} // 0;
    my @res = ({year=>$year, index=>$index});

    my $i = 0;
    if (defined $args{yearly_rate}) {
        while ($i++ < $args{years}) {
            $year++;
            $index *= 1 + $args{yearly_rate}/100;
            push @res, {
                year  => $year,
                index => sprintf("%.4f", $index),
            };
        }
    } else {
        my $rates = $args{rates};
        while ($i++ <= $#{$rates}) {
            my $rate = $rates->[$year];
            $index *= 1 + $rate/100;
            $year++;
            push @res, {
                year  => $year,
                rate  => sprintf("%.2f%%", $rate),
                index => sprintf("%.4f", $index),
            };
        }
    }

    \@res;
}

1;
# ABSTRACT: Calculate accumulated inflation (or savings rate, etc) over the years

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CalcAccumulatedInflation - Calculate accumulated inflation (or savings rate, etc) over the years

=head1 VERSION

This document describes version 0.052 of App::CalcAccumulatedInflation (from Perl distribution App-CalcAccumulatedInflation), released on 2021-07-17.

=head1 SYNOPSIS

See the included script L<calc-accumulated-inflation>.

=head1 CONTRIBUTOR

=for stopwords perlancar (on netbook-dell-xps13)

perlancar (on netbook-dell-xps13) <perlancar@gmail.com>

=head1 FUNCTIONS


=head2 calc_accumulated_inflation

Usage:

 calc_accumulated_inflation(%args) -> any

Calculate accumulated inflation (or savings rate, etc) over the years.

Examples:

=over

=item * See accumulated 6%E<sol>year inflation for 10 years:

 calc_accumulated_inflation(yearly_rate => 6);

Result:

 [
   { index => 1, year => 0 },
   { index => "1.0600", year => 1 },
   { index => 1.1236, year => 2 },
   { index => "1.1910", year => 3 },
   { index => 1.2625, year => 4 },
   { index => 1.3382, year => 5 },
   { index => 1.4185, year => 6 },
   { index => 1.5036, year => 7 },
   { index => 1.5938, year => 8 },
   { index => 1.6895, year => 9 },
   { index => 1.7908, year => 10 },
 ]

=item * See accumulated 5.5%E<sol>year inflation for 7 years:

 calc_accumulated_inflation(yearly_rate => 5.5, years => 7);

Result:

 [
   { index => 1, year => 0 },
   { index => "1.0550", year => 1 },
   { index => "1.1130", year => 2 },
   { index => 1.1742, year => 3 },
   { index => 1.2388, year => 4 },
   { index => "1.3070", year => 5 },
   { index => 1.3788, year => 6 },
   { index => 1.4547, year => 7 },
 ]

=item * Indonesia's inflation rate for 2003-2014:

 calc_accumulated_inflation(rates => [5.16, 6.4, 17.11, 6.6, 6.59, 11.06, 2.78, 6.96, 3.79, 4.3, 8.38, 8.36]);

Result:

 [
   { index => 1, year => 0 },
   { index => 1.0516, rate => "5.16%", year => 1 },
   { index => 1.1189, rate => "6.40%", year => 2 },
   { index => 1.3103, rate => "17.11%", year => 3 },
   { index => 1.3968, rate => "6.60%", year => 4 },
   { index => 1.4889, rate => "6.59%", year => 5 },
   { index => 1.6536, rate => "11.06%", year => 6 },
   { index => 1.6995, rate => "2.78%", year => 7 },
   { index => 1.8178, rate => "6.96%", year => 8 },
   { index => 1.8867, rate => "3.79%", year => 9 },
   { index => 1.9678, rate => "4.30%", year => 10 },
   { index => 2.1327, rate => "8.38%", year => 11 },
   { index => "2.3110", rate => "8.36%", year => 12 },
 ]

=item * How much will your $100,000 grow over the next 10 years, if the savings rate is 4%; assuming this year is 2021:

 calc_accumulated_inflation(base_index => 100000, base_year => 2021, yearly_rate => 4, years => 10);

Result:

 [
   { index => 100000, year => 2021 },
   { index => "104000.0000", year => 2022 },
   { index => "108160.0000", year => 2023 },
   { index => "112486.4000", year => 2024 },
   { index => "116985.8560", year => 2025 },
   { index => 121665.2902, year => 2026 },
   { index => 126531.9018, year => 2027 },
   { index => 131593.1779, year => 2028 },
   { index => "136856.9050", year => 2029 },
   { index => 142331.1812, year => 2030 },
   { index => 148024.4285, year => 2031 },
 ]

=back

This routine generates a table of accumulated inflation over a period of several
years. You can either specify a fixed rate for every years (C<yearly_rate>), or
specify each year's rates (C<rates>). You can also optionally set base index
(default to 1) and base year (default to 0).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<base_index> => I<float> (default: 1)

=item * B<base_year> => I<float> (default: 0)

=item * B<rates> => I<array[float]>

Different rates for each year, in percent.

=item * B<yearly_rate> => I<float>

A single rate for every year, in percent.

=item * B<years> => I<int> (default: 10)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CalcAccumulatedInflation>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CalcAccumulatedInflation>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CalcAccumulatedInflation>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
