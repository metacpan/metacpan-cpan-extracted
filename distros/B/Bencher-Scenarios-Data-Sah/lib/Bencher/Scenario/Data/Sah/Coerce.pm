package Bencher::Scenario::Data::Sah::Coerce;

use strict;

require Data::Sah::Coerce;
require DateTime;
require Time::Moment;

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
            code_template => 'state $c = Data::Sah::Coerce::gen_coercer(type => <type>, coerce_to => <coerce_to>); $c->(<data>)',
        },
    ],
    datasets => [
        {
            name => 'date (coerce to float(epoch))',
            args => {
                type => 'date',
                coerce_to => 'float(epoch)',
                'data@' => [undef, "abc", 123, [], 1463373166, "2016-05-16"],
            },
        },
        # XXX date (coerce to DateTime)
        # XXX date (coerce to Time::Moment)
    ],
};

1;
# ABSTRACT: Benchmark coercion

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::Coerce - Benchmark coercion

=head1 VERSION

This document describes version 0.071 of Bencher::Scenario::Data::Sah::Coerce (from Perl distribution Bencher-Scenarios-Data-Sah), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Sah::Coerce

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_coercer (perl_code)

Code template:

 state $c = Data::Sah::Coerce::gen_coercer(type => <type>, coerce_to => <coerce_to>); $c->(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * date (coerce to float(epoch))

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Sah::Coerce >>):

 #table1#
 +-----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | arg_data              | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | 2016-05-16            |    110000 |  9        |                 0.00% |              7950.82% | 1.7e-08 |      20 |
 | 1463373166            |   2332000 |  0.428817 |              2005.92% |               282.29% |   0     |      20 |
 | abc                   |   3000000 |  0.4      |              2275.14% |               238.96% | 4.1e-09 |      20 |
 | 123                   |   2900000 |  0.34     |              2520.24% |               207.25% | 3.1e-09 |      20 |
 | ARRAY(0x5640c2d368e0) |   2900000 |  0.34     |              2527.74% |               206.38% | 4.2e-10 |      20 |
 |                       |   8900000 |  0.11     |              7950.82% |                 0.00% | 2.1e-10 |      20 |
 +-----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                              Rate  2016-05-16  1463373166   abc   123  ARRAY(0x5640c2d368e0)       
  2016-05-16              110000/s          --        -95%  -95%  -96%                   -96%  -98% 
  1463373166             2332000/s       1998%          --   -6%  -20%                   -20%  -74% 
  abc                    3000000/s       2150%          7%    --  -15%                   -15%  -72% 
  123                    2900000/s       2547%         26%   17%    --                     0%  -67% 
  ARRAY(0x5640c2d368e0)  2900000/s       2547%         26%   17%    0%                     --  -67% 
                         8900000/s       8081%        289%  263%  209%                   209%    -- 
 
 Legends:
   : arg_data=
   123: arg_data=123
   1463373166: arg_data=1463373166
   2016-05-16: arg_data=2016-05-16
   ARRAY(0x5640c2d368e0): arg_data=ARRAY(0x5640c2d368e0)
   abc: arg_data=abc

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
