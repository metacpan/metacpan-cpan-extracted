package Bencher::Scenario::Data::Sah::Startup;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Sah'; # DIST
our $VERSION = '0.071'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of loading Data::Sah and generating validators',
    participants => [
        { name => 'perl'               , perl_cmdline => ["-e1"] },
        { name => 'load_dsah'          , perl_cmdline => ["-MData::Sah", "-e", 1] },
        { name => 'load_dsah+get_plc'  , perl_cmdline => ["-MData::Sah", "-e", '$sah = Data::Sah->new; $plc = $sah->get_compiler("perl")'] },
        { name => 'genval_bool_int'    , perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'gen_validator("int")'] },
        { name => 'genval_str_int'     , perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'gen_validator("int",{return_type=>"str"})'] },
        { name => 'genval_str_date'    , perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'gen_validator("date",{return_type=>"str"})'] },
        { name => 'genval_str_5typical', perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'for ("int", "str*", [int=>min=>1, max=>10], [str, min_len=>4], [any=>of=>["str",["array",of=>"str"]]]) { gen_validator("int",{return_type=>"str"}) }'] },
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of loading Data::Sah and generating validators

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::Startup - Benchmark startup overhead of loading Data::Sah and generating validators

=head1 VERSION

This document describes version 0.071 of Bencher::Scenario::Data::Sah::Startup (from Perl distribution Bencher-Scenarios-Data-Sah), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Sah::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (command)



=item * load_dsah (command)



=item * load_dsah+get_plc (command)



=item * genval_bool_int (command)



=item * genval_str_int (command)



=item * genval_str_date (command)



=item * genval_str_5typical (command)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Sah::Startup >>):

 #table1#
 +---------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant         | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | genval_str_5typical |        18 |      56   |                 0.00% |               715.12% |   0.00019 |      20 |
 | genval_str_int      |        19 |      54   |                 3.73% |               685.82% |   0.00014 |      20 |
 | genval_bool_int     |        19 |      53   |                 4.45% |               680.41% |   0.00021 |      20 |
 | genval_str_date     |        19 |      53   |                 5.59% |               671.97% |   0.00022 |      20 |
 | load_dsah+get_plc   |        38 |      27   |               108.66% |               290.64% |   5e-05   |      20 |
 | load_dsah           |        80 |      13   |               343.90% |                83.63% | 6.3e-05   |      20 |
 | perl                |       150 |       6.8 |               715.12% |                 0.00% | 3.2e-05   |      20 |
 +---------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

          Rate  g_s_5  g_s_i  g_b_i  g_s_d  l_d_p   l_d     p 
  g_s_5   18/s     --    -3%    -5%    -5%   -51%  -76%  -87% 
  g_s_i   19/s     3%     --    -1%    -1%   -50%  -75%  -87% 
  g_b_i   19/s     5%     1%     --     0%   -49%  -75%  -87% 
  g_s_d   19/s     5%     1%     0%     --   -49%  -75%  -87% 
  l_d_p   38/s   107%   100%    96%    96%     --  -51%  -74% 
  l_d     80/s   330%   315%   307%   307%   107%    --  -47% 
  p      150/s   723%   694%   679%   679%   297%   91%    -- 
 
 Legends:
   g_b_i: participant=genval_bool_int
   g_s_5: participant=genval_str_5typical
   g_s_d: participant=genval_str_date
   g_s_i: participant=genval_str_int
   l_d: participant=load_dsah
   l_d_p: participant=load_dsah+get_plc
   p: participant=perl

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
