package Bencher::Scenario::Data::CSel::Startup;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenarios-Data-CSel'; # DIST
our $VERSION = '0.041'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of loading Data::CSel and parsing expressions',
    participants => [
        { name => 'perl',            perl_cmdline => ["-e1"] },
        { name => 'load_csel',       perl_cmdline => ["-MData::CSel", "-e1"] },
        { name => 'load_csel_parse', perl_cmdline => ["-MData::CSel=parse_csel", "-e", "parse_csel(q(E F))"] },
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of loading Data::CSel and parsing expressions

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::CSel::Startup - Benchmark startup overhead of loading Data::CSel and parsing expressions

=head1 VERSION

This document describes version 0.041 of Bencher::Scenario::Data::CSel::Startup (from Perl distribution Bencher-Scenarios-Data-CSel), released on 2023-01-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::CSel::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (command)



=item * load_csel (command)



=item * load_csel_parse (command)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::CSel::Startup >>):

 #table1#
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | load_csel_parse |        60 |      17   |                 0.00% |               113.46% | 6.9e-05 |      20 |
 | load_csel       |        63 |      16   |                 4.58% |               104.12% | 7.4e-05 |      20 |
 | perl            |       130 |       7.8 |               113.46% |                 0.00% | 3.6e-05 |      20 |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

          Rate  l_c_p   l_c     p 
  l_c_p   60/s     --   -5%  -54% 
  l_c     63/s     6%    --  -51% 
  p      130/s   117%  105%    -- 
 
 Legends:
   l_c: participant=load_csel
   l_c_p: participant=load_csel_parse
   p: participant=perl

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-CSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-CSel>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-CSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
