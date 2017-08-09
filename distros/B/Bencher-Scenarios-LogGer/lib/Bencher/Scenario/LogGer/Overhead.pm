package Bencher::Scenario::LogGer::Overhead;

our $DATE = '2017-08-04'; # DATE
our $VERSION = '0.012'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

my ($fh, $fname) = tempfile();

our $scenario = {
    summary => 'Measure startup overhead of various codes',
    modules => {
        'Log::Any' => {},
        'Log::ger' => {version=>'0.019'},
        'Log::ger::App' => {version=>'0.002'},
        'Log::ger::Output' => {version=>'0.005'},
        'Log::ger::Layout::Pattern' => {version=>'0'},
        'Log::Contextual' => {version=>'0'},
        'Log::Log4perl' => {version=>'0'},
        'Log::Log4perl::Tiny' => {version=>'0'},
        'Log::Dispatchouli' => {version=>'0'},
    },
    code_startup => 1,
    participants => [
        {code_template=>'use Log::ger ();'},
        {code_template=>'use Log::ger;'},
        {code_template=>'use Log::ger; Log::ger->get_logger;'},
        {code_template=>'use Log::ger::App;'},
        {code_template=>'use Log::ger::App; use Log::ger;'},
        {code_template=>'use Log::ger::Plugin::OptAway; use Log::ger;'},
        {code_template=>'use Log::ger::Like::LogAny;'},
        {code_template=>'use Log::ger::Like::Log4perl;'},
        {code_template=>'use Log::ger::App;'},

        {code_template=>'use Log::Any;'},
        {code_template=>'use Log::Any q($log);'},

        {code_template=>'use Log::Contextual qw(:log);'},

        {code_template=>'use Log::Log4perl;'},

        {code_template=>'use Log::Log4perl::Tiny;'},

        {code_template=>'use Log::Dispatchouli;'},

        {code_template=>'use Log::ger::Output::Screen;', tags=>['output']},
        {code_template=>'use Log::ger::Output::Composite;', tags=>['output']},

        # TODO: Lg + Composite (2 outputs)
        # TODO: Lg + Composite (2 outputs + pattern layouts)
        # TODO: Log::Any + Screen
        # TODO: Log::Log4perl + easy_init
    ],
};

1;
# ABSTRACT: Measure startup overhead of various codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogGer::Overhead - Measure startup overhead of various codes

=head1 VERSION

This document describes version 0.012 of Bencher::Scenario::LogGer::Overhead (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-08-04.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.049

L<Log::Contextual> 0.007001

L<Log::Dispatchouli> 2.015

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.023

L<Log::ger::App> 0.003

L<Log::ger::Layout::Pattern> 0.001

L<Log::ger::Output> 0.023

=head1 BENCHMARK PARTICIPANTS

=over

=item * use Log::ger (); (perl_code)

Code template:

 use Log::ger ();



=item * use Log::ger; (perl_code)

Code template:

 use Log::ger;



=item * use Log::ger; Log::ger->get_logger; (perl_code)

Code template:

 use Log::ger; Log::ger->get_logger;



=item * use Log::ger::App; (perl_code)

Code template:

 use Log::ger::App;



=item * use Log::ger::App; use Log::ger; (perl_code)

Code template:

 use Log::ger::App; use Log::ger;



=item * use Log::ger::Plugin::OptAway; use Log::ger; (perl_code)

Code template:

 use Log::ger::Plugin::OptAway; use Log::ger;



=item * use Log::ger::Like::LogAny; (perl_code)

Code template:

 use Log::ger::Like::LogAny;



=item * use Log::ger::Like::Log4perl; (perl_code)

Code template:

 use Log::ger::Like::Log4perl;



=item * use Log::ger::App; (perl_code)

Code template:

 use Log::ger::App;



=item * use Log::Any; (perl_code)

Code template:

 use Log::Any;



=item * use Log::Any q($log); (perl_code)

Code template:

 use Log::Any q($log);



=item * use Log::Contextual qw(:log); (perl_code)

Code template:

 use Log::Contextual qw(:log);



=item * use Log::Log4perl; (perl_code)

Code template:

 use Log::Log4perl;



=item * use Log::Log4perl::Tiny; (perl_code)

Code template:

 use Log::Log4perl::Tiny;



=item * use Log::Dispatchouli; (perl_code)

Code template:

 use Log::Dispatchouli;



=item * use Log::ger::Output::Screen; (perl_code) [output]

Code template:

 use Log::ger::Output::Screen;



=item * use Log::ger::Output::Composite; (perl_code) [output]

Code template:

 use Log::ger::Output::Composite;



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m LogGer::Overhead >>):

 #table1#
 +----------------------------------------------+------------------------------+--------------------+----------------+-----------+-------------------------+------------+-----------+---------+
 | participant                                  | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | code_overhead_time (ms) | vs_slowest |  errors   | samples |
 +----------------------------------------------+------------------------------+--------------------+----------------+-----------+-------------------------+------------+-----------+---------+
 | use Log::Dispatchouli;                       | 568                          | 4                  | 20             |     130   |                   124   |        1   |   0.00023 |      20 |
 | use Log::Contextual qw(:log);                | 572                          | 4                  | 20             |      94   |                    88   |        1.3 |   0.00017 |      20 |
 | use Log::Log4perl;                           | 568                          | 3.9                | 20             |      45   |                    39   |        2.8 |   0.00013 |      20 |
 | use Log::ger::App; use Log::ger;             | 572                          | 3.9                | 20             |      27   |                    21   |        4.6 | 7.9e-05   |      20 |
 | use Log::Log4perl::Tiny;                     | 572                          | 4                  | 20             |      25   |                    19   |        5.1 | 3.6e-05   |      20 |
 | use Log::ger::App;                           | 572                          | 3.9                | 20             |      19   |                    13   |        6.7 | 4.3e-05   |      21 |
 | use Log::ger::Like::Log4perl;                | 572                          | 4                  | 20             |      18   |                    12   |        6.9 | 6.1e-05   |      20 |
 | use Log::Any q($log);                        | 572                          | 4                  | 20             |      18   |                    12   |        7.1 | 7.3e-05   |      22 |
 | use Log::Any;                                | 572                          | 4                  | 20             |      17   |                    11   |        7.6 | 6.4e-05   |      20 |
 | use Log::ger::Output::Screen;                | 568                          | 4                  | 20             |      13   |                     7   |        9.5 | 3.9e-05   |      20 |
 | use Log::ger::Output::Composite;             | 572                          | 3.9                | 20             |      10   |                     4   |       13   |   2e-05   |      20 |
 | use Log::ger::Plugin::OptAway; use Log::ger; | 572                          | 4                  | 20             |       9.9 |                     3.9 |       13   | 2.5e-05   |      20 |
 | use Log::ger::Like::LogAny;                  | 568                          | 3.9                | 20             |       7.4 |                     1.4 |       17   |   3e-05   |      20 |
 | use Log::ger; Log::ger->get_logger;          | 572                          | 4                  | 20             |       7   |                     1   |       20   | 7.2e-05   |      20 |
 | use Log::ger;                                | 572                          | 4                  | 20             |       7   |                     1   |       20   | 7.5e-05   |      20 |
 | use Log::ger ();                             | 568                          | 4                  | 20             |       7   |                     1   |       18   | 1.7e-05   |      20 |
 | perl -e1 (baseline)                          | 568                          | 4                  | 20             |       6   |                     0   |       20   | 6.5e-05   |      20 |
 +----------------------------------------------+------------------------------+--------------------+----------------+-----------+-------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogGer>

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
