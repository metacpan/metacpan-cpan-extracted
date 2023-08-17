package Bencher::Scenario::Data::Sah::gen_coercer;

use strict;

require Data::Sah::Coerce;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Sah'; # DIST
our $VERSION = '0.071'; # VERSION

my $return_types = ['bool', 'str', 'full'];

our $scenario = {
    summary => 'Benchmark coercion',
    participants => [
        {
            name => 'gen_coercer',
            code_template => 'Data::Sah::Coerce::gen_coercer(type => <type>, coerce_to => <coerce_to>)',
        },
    ],
    datasets => [
        {
            name => 'date (coerce to float(epoch))',
            args => {
                type => 'date',
                coerce_to => 'float(epoch)',
            },
        },
        {
            name => 'date (coerce to DateTime)',
            args => {
                type => 'date',
                coerce_to => 'DateTime',
            },
        },
        {
            name => 'date (coerce to Time::Moment)',
            args => {
                type => 'date',
                coerce_to => 'Time::Moment',
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark coercion

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::gen_coercer - Benchmark coercion

=head1 VERSION

This document describes version 0.071 of Bencher::Scenario::Data::Sah::gen_coercer (from Perl distribution Bencher-Scenarios-Data-Sah), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Sah::gen_coercer

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_coercer (perl_code)

Code template:

 Data::Sah::Coerce::gen_coercer(type => <type>, coerce_to => <coerce_to>)



=back

=head1 BENCHMARK DATASETS

=over

=item * date (coerce to float(epoch))

=item * date (coerce to DateTime)

=item * date (coerce to Time::Moment)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Sah::gen_coercer >>):

 #table1#
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset                       | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | date (coerce to Time::Moment) |      3000 |       300 |                 0.00% |                18.96% | 7.8e-06 |      20 |
 | date (coerce to DateTime)     |      3600 |       280 |                 9.76% |                 8.38% | 4.3e-07 |      20 |
 | date (coerce to float(epoch)) |      3900 |       260 |                18.96% |                 0.00% | 2.7e-07 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                   Rate  date (coerce to Time::Moment)  date (coerce to DateTime)  date (coerce to float(epoch)) 
  date (coerce to Time::Moment)  3000/s                             --                        -6%                           -13% 
  date (coerce to DateTime)      3600/s                             7%                         --                            -7% 
  date (coerce to float(epoch))  3900/s                            15%                         7%                             -- 
 
 Legends:
   date (coerce to DateTime): dataset=date (coerce to DateTime)
   date (coerce to Time::Moment): dataset=date (coerce to Time::Moment)
   date (coerce to float(epoch)): dataset=date (coerce to float(epoch))

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Sah>.

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

This software is copyright (c) 2023, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
