package App::CalcAccumulatedDiscounts;

our $DATE = '2017-06-05'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{calc_accumulated_discounts} = {
    v => 1.1,
    summary => 'Calculate multi-year discounts from a per-year discount rate',
    description => <<'_',

This routine generates a table of accumulated discounts over a period of several
years, given the annual discount rates.

I first wrote this to see the accumulated fees when choosing mutual funds
products. The moral of the story is, if you plan to hold a fund for a long time
(e.g. 5-10 years or longer) you should pick funds that are low in annual fees
(e.g. 1% or lower). Otherwise, the annual management fees will eat up most, if
not all, your potential profits.

_
    args => {
        years => {
            schema => ['array*', of=>'int*'],
            default => [5,10,15,20,25,30,35,40,45,50],
        },
        discounts => {
            schema => ['array*', of=>'float*'], # XXX percent
            default => [0.25, 0.5, 0.75, 1,
                        1.25, 1.5, 1.75, 2,
                        2.25, 2.5, 2.75, 3,
                        3.25, 3.5, 3.75, 4,
                        4.5, 5],
        },
    },
    examples => [
        {
            args => {},
        },
        {
            summary => 'Modify years and discount rates to generate',
            args => {years=>[5,10], discounts=>[1,2,2.5]},
        },
    ],
    result_naked => 1,
};
sub calc_accumulated_discounts {
    my %args = @_;

    my $years = $args{years};
    my $discounts = $args{discounts};

    my $res = [];
    $res->[0][0] = 'Disc p.a. \\ Year';

    my $i = 0;
    for my $disc (@$discounts) {
        $i++;
        $res->[$i][0] = sprintf("%.2f%%", $disc);
        my $j = 0;
        for my $year (@$years) {
            $j++;
            if ($i == 1) {
                $res->[0][$j] = $year."y";
            }
            $res->[$i][$j] = sprintf("%.1f%%", (1 - (1-$disc/100)**$year)*100);
        }
    }

    $res;
}

1;
# ABSTRACT: Calculate multi-year discounts from a per-year discount rate

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CalcAccumulatedDiscounts - Calculate multi-year discounts from a per-year discount rate

=head1 VERSION

This document describes version 0.07 of App::CalcAccumulatedDiscounts (from Perl distribution App-CalcAccumulatedDiscounts), released on 2017-06-05.

=head1 SYNOPSIS

See the included script L<calc-accumulated-discounts>.

=head1 FUNCTIONS


=head2 calc_accumulated_discounts

Usage:

 calc_accumulated_discounts(%args) -> any

Calculate multi-year discounts from a per-year discount rate.

Examples:

=over

=item * Example #1:

 calc_accumulated_discounts();

Result:

 [
   [
     "Disc p.a. \\ Year",
     "5y",
     "10y",
     "15y",
     "20y",
     "25y",
     "30y",
     "35y",
     "40y",
     "45y",
     "50y",
   ],
   [
     "0.25%",
     "1.2%",
     "2.5%",
     "3.7%",
     "4.9%",
     "6.1%",
     "7.2%",
     "8.4%",
     "9.5%",
     "10.7%",
     "11.8%",
   ],
   [
     "0.50%",
     "2.5%",
     "4.9%",
     "7.2%",
     "9.5%",
     "11.8%",
     "14.0%",
     "16.1%",
     "18.2%",
     "20.2%",
     "22.2%",
   ],
   [
     "0.75%",
     "3.7%",
     "7.3%",
     "10.7%",
     "14.0%",
     "17.2%",
     "20.2%",
     "23.2%",
     "26.0%",
     "28.7%",
     "31.4%",
   ],
   [
     "1.00%",
     "4.9%",
     "9.6%",
     "14.0%",
     "18.2%",
     "22.2%",
     "26.0%",
     "29.7%",
     "33.1%",
     "36.4%",
     "39.5%",
   ],
   [
     "1.25%",
     "6.1%",
     "11.8%",
     "17.2%",
     "22.2%",
     "27.0%",
     "31.4%",
     "35.6%",
     "39.5%",
     "43.2%",
     "46.7%",
   ],
   [
     "1.50%",
     "7.3%",
     "14.0%",
     "20.3%",
     "26.1%",
     "31.5%",
     "36.5%",
     "41.1%",
     "45.4%",
     "49.3%",
     "53.0%",
   ],
   [
     "1.75%",
     "8.4%",
     "16.2%",
     "23.3%",
     "29.7%",
     "35.7%",
     "41.1%",
     "46.1%",
     "50.6%",
     "54.8%",
     "58.6%",
   ],
   [
     "2.00%",
     "9.6%",
     "18.3%",
     "26.1%",
     "33.2%",
     "39.7%",
     "45.5%",
     "50.7%",
     "55.4%",
     "59.7%",
     "63.6%",
   ],
   [
     "2.25%",
     "10.8%",
     "20.4%",
     "28.9%",
     "36.6%",
     "43.4%",
     "49.5%",
     "54.9%",
     "59.8%",
     "64.1%",
     "67.9%",
   ],
   [
     "2.50%",
     "11.9%",
     "22.4%",
     "31.6%",
     "39.7%",
     "46.9%",
     "53.2%",
     "58.8%",
     "63.7%",
     "68.0%",
     "71.8%",
   ],
   [
     "2.75%",
     "13.0%",
     "24.3%",
     "34.2%",
     "42.7%",
     "50.2%",
     "56.7%",
     "62.3%",
     "67.2%",
     "71.5%",
     "75.2%",
   ],
   [
     "3.00%",
     "14.1%",
     "26.3%",
     "36.7%",
     "45.6%",
     "53.3%",
     "59.9%",
     "65.6%",
     "70.4%",
     "74.6%",
     "78.2%",
   ],
   [
     "3.25%",
     "15.2%",
     "28.1%",
     "39.1%",
     "48.4%",
     "56.2%",
     "62.9%",
     "68.5%",
     "73.3%",
     "77.4%",
     "80.8%",
   ],
   [
     "3.50%",
     "16.3%",
     "30.0%",
     "41.4%",
     "51.0%",
     "59.0%",
     "65.7%",
     "71.3%",
     "76.0%",
     "79.9%",
     "83.2%",
   ],
   [
     "3.75%",
     "17.4%",
     "31.8%",
     "43.6%",
     "53.4%",
     "61.5%",
     "68.2%",
     "73.8%",
     "78.3%",
     "82.1%",
     "85.2%",
   ],
   [
     "4.00%",
     "18.5%",
     "33.5%",
     "45.8%",
     "55.8%",
     "64.0%",
     "70.6%",
     "76.0%",
     "80.5%",
     "84.1%",
     "87.0%",
   ],
   [
     "4.50%",
     "20.6%",
     "36.9%",
     "49.9%",
     "60.2%",
     "68.4%",
     "74.9%",
     "80.0%",
     "84.1%",
     "87.4%",
     "90.0%",
   ],
   [
     "5.00%",
     "22.6%",
     "40.1%",
     "53.7%",
     "64.2%",
     "72.3%",
     "78.5%",
     "83.4%",
     "87.1%",
     "90.1%",
     "92.3%",
   ],
 ]

=item * Modify years and discount rates to generate:

 calc_accumulated_discounts(discounts => [1, 2, 2.5], years => [5, 10]);

Result:

 [
   ["Disc p.a. \\ Year", "5y", "10y"],
   ["1.00%", "4.9%", "9.6%"],
   ["2.00%", "9.6%", "18.3%"],
   ["2.50%", "11.9%", "22.4%"],
 ]

=back

This routine generates a table of accumulated discounts over a period of several
years, given the annual discount rates.

I first wrote this to see the accumulated fees when choosing mutual funds
products. The moral of the story is, if you plan to hold a fund for a long time
(e.g. 5-10 years or longer) you should pick funds that are low in annual fees
(e.g. 1% or lower). Otherwise, the annual management fees will eat up most, if
not all, your potential profits.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<discounts> => I<array[float]> (default: [0.25,0.5,0.75,1,1.25,1.5,1.75,2,2.25,2.5,2.75,3,3.25,3.5,3.75,4,4.5,5])

=item * B<years> => I<array[int]> (default: [5,10,15,20,25,30,35,40,45,50])

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CalcAccumulatedDiscounts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CalcAccumulatedDiscount>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CalcAccumulatedDiscounts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
