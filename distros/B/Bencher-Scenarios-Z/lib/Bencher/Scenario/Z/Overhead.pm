package Bencher::Scenario::Z::Overhead;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-08'; # DATE
our $DIST = 'Bencher-Scenarios-Z'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure startup overhead of Z',
    code_startup => 1,
    participants => [
        # the extra_modules is there so the Pod::Weaver plugin can show the used
        # module's versions
        {code_template=>'use Z;', extra_modules=>['Z']},
        {code_template=>'use Z -modern;', extra_modules=>['Z']},
        {code_template=>'use Z -compat;', extra_modules=>['Z']},
        {code_template=>'use Z -detect;', extra_modules=>['Z']},

        {code_template=>'use Type::Tiny;', extra_modules=>['Type::Tiny']},
        {code_template=>'use Types::Standard;', extra_modules=>['Types::Standard']},

        {code_template=>'use Zydeco;', extra_modules=>['Zydeco']},

        {code_template=>'use Zydeco::Lite;', extra_modules=>['Zydeco::Lite']},

        {code_template=>'use MooX::Press;', extra_modules=>['MooX::Press']},

        {code_template=>'use Moo;', extra_modules=>['Moo']},

        {code_template=>'use Moose;', extra_modules=>['Moose']},
    ],
};

1;
# ABSTRACT: Measure startup overhead of Z

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Z::Overhead - Measure startup overhead of Z

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::Z::Overhead (from Perl distribution Bencher-Scenarios-Z), released on 2020-10-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Z::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * use Z; (perl_code)

Code template:

 use Z;



=item * use Z -modern; (perl_code)

Code template:

 use Z -modern;



=item * use Z -compat; (perl_code)

Code template:

 use Z -compat;



=item * use Z -detect; (perl_code)

Code template:

 use Z -detect;



=item * use Type::Tiny; (perl_code)

Code template:

 use Type::Tiny;



=item * use Types::Standard; (perl_code)

Code template:

 use Types::Standard;



=item * use Zydeco; (perl_code)

Code template:

 use Zydeco;



=item * use Zydeco::Lite; (perl_code)

Code template:

 use Zydeco::Lite;



=item * use MooX::Press; (perl_code)

Code template:

 use MooX::Press;



=item * use Moo; (perl_code)

Code template:

 use Moo;



=item * use Moose; (perl_code)

Code template:

 use Moose;



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m Z::Overhead >>):

 #table1#
 +----------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+
 | participant          | time (ms) | code_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +----------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+
 | use Zydeco;          |     164   |              157.3 |                 0.00% |              2338.27% |   0.00013 |      20 |
 | use Moose;           |     140   |              133.3 |                19.30% |              1943.85% |   0.00022 |      20 |
 | use Z;               |     120   |              113.3 |                35.02% |              1705.90% |   0.00021 |      20 |
 | use Z -modern;       |     120   |              113.3 |                35.83% |              1695.06% |   0.00013 |      20 |
 | use Z -detect;       |     120   |              113.3 |                36.25% |              1689.55% |   0.00017 |      20 |
 | use Z -compat;       |     120   |              113.3 |                37.35% |              1675.24% | 8.9e-05   |      20 |
 | use MooX::Press;     |      91   |               84.3 |                80.00% |              1254.63% |   0.00013 |      20 |
 | use Zydeco::Lite;    |      75   |               68.3 |               117.93% |              1018.85% | 8.1e-05   |      20 |
 | use Types::Standard; |      44   |               37.3 |               271.61% |               556.13% | 5.6e-05   |      20 |
 | use Type::Tiny;      |      18.3 |               11.6 |               798.93% |               171.24% | 1.3e-05   |      20 |
 | use Moo;             |      18   |               11.3 |               809.10% |               168.21% | 2.5e-05   |      20 |
 | perl -e1 (baseline)  |       6.7 |                0   |              2338.27% |                 0.00% | 1.7e-05   |      20 |
 +----------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Z>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Z>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Z>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
