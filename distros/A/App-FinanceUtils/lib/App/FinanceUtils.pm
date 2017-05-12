package App::FinanceUtils;

our $DATE = '2017-03-14'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::FromFormulas qw(gen_funcs_from_formulas);

our %SPEC;

my $res = gen_funcs_from_formulas(
    prefix => 'calc_fv_',
    symbols => {
        fv => {
            caption => 'future value',
            schema => ['float*'],
        },
        pv => {
            caption => 'present value',
            schema => ['float*'],
        },
        r => {
            caption => 'return rate',
            summary => 'Return rate (e.g. 0.06 for 6%)',
            schema => ['float*', 'x.perl.coerce_rules'=>['str_percent']],
        },
        n => {
            caption => 'periods',
            summary => 'Number of periods',
            schema => ['float*'],
        },
    },
    formulas => [
        {
            formula => 'fv = pv*(1+r)**n',
            examples => [
                {
                    summary => 'Invest $100 at 6% annual return rate for 5 years',
                    args => {pv=>100, r=>0.06, n=>5},
                },
                {
                    summary => 'Ditto, using percentage notation on command-line',
                    src => '[[prog]] 100 6% 5',
                    src_plang => 'bash',
                },
            ],
        },
        {
            formula => 'pv = fv/(1+r)**n',
            examples => [
                {
                    summary => 'Want to get $100 after 5 years at 6% annual return rate, how much to invest?',
                    args => {fv=>100, r=>0.06, n=>5},
                },
            ],
        },
        {
            formula => 'r = (fv/pv)**(1/n) - 1',
            examples => [
                {
                    summary => 'Want to get $120 in 5 years using $100 investment, what is the required return rate?',
                    args => {fv=>120, pv=>100, n=>5},
                },
            ],
        },
        {
            formula => 'n = log(fv/pv) / log(1+r)',
            examples => [
                {
                    summary => 'Want to get $120 using $100 investment with annual 6% return rate, how many years must we wait?',
                    args => {fv=>120, pv=>100, r=>0.06},
                },
            ],
        },
    ],
);
$res->[0] == 200 or die "Can't generate calc_fv_* functions: $res->[0] - $res->[1]";

1;
# ABSTRACT: Financial CLI utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FinanceUtils - Financial CLI utilities

=head1 VERSION

This document describes version 0.002 of App::FinanceUtils (from Perl distribution App-FinanceUtils), released on 2017-03-14.

=head1 DESCRIPTION

This distribution contains some CLI's to do financial calculations:

# INSERT_EXECS_LIST

=head1 FUNCTIONS


=head2 calc_fv_future_value

Usage:

 calc_fv_future_value(%args) -> any

Calculate future value (fv) from present value (pv), return rate (r), and periods (n).

Examples:

=over

=item * Invest $100 at 6% annual return rate for 5 years:

 calc_fv_future_value(pv => 100, r => 0.06, n => 5); # -> 133.82255776

=back

Formula is:

 fv = pv*(1+r)**n

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<n>* => I<float>

Number of periods.

=item * B<pv>* => I<float>

present value.

=item * B<r>* => I<float>

Return rate (e.g. 0.06 for 6%).

=back

Return value:  (any)


=head2 calc_fv_periods

Usage:

 calc_fv_periods(%args) -> any

Calculate periods (n) from future value (fv), present value (pv), and return rate (r).

Examples:

=over

=item * Want to get $120 using $100 investment with annual 6% return rate, how many years must we wait?:

 calc_fv_periods(fv => 120, pv => 100, r => 0.06); # -> 3.12896813521953

=back

Formula is:

 n = log(fv/pv) / log(1+r)

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<fv>* => I<float>

future value.

=item * B<pv>* => I<float>

present value.

=item * B<r>* => I<float>

Return rate (e.g. 0.06 for 6%).

=back

Return value:  (any)


=head2 calc_fv_present_value

Usage:

 calc_fv_present_value(%args) -> any

Calculate present value (pv) from future value (fv), return rate (r), and periods (n).

Examples:

=over

=item * Want to get $100 after 5 years at 6% annual return rate, how much to invest?:

 calc_fv_present_value(fv => 100, r => 0.06, n => 5); # -> 74.7258172866057

=back

Formula is:

 pv = fv/(1+r)**n

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<fv>* => I<float>

future value.

=item * B<n>* => I<float>

Number of periods.

=item * B<r>* => I<float>

Return rate (e.g. 0.06 for 6%).

=back

Return value:  (any)


=head2 calc_fv_return_rate

Usage:

 calc_fv_return_rate(%args) -> any

Calculate return rate (r) from future value (fv), present value (pv), and periods (n).

Examples:

=over

=item * Want to get $120 in 5 years using $100 investment, what is the required return rate?:

 calc_fv_return_rate(fv => 120, pv => 100, n => 5); # -> 0.0371372893366482

=back

Formula is:

 r = (fv/pv)**(1/n) - 1

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<fv>* => I<float>

future value.

=item * B<n>* => I<float>

Number of periods.

=item * B<pv>* => I<float>

present value.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FinanceUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FinanceUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FinanceUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
