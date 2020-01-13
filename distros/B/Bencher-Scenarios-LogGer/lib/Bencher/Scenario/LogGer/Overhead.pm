package Bencher::Scenario::LogGer::Overhead;

our $DATE = '2020-01-13'; # DATE
our $VERSION = '0.016'; # VERSION

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
        'Log::Dispatch' => {version=>'0'},
        'Log::Dispatch::Null' => {version=>'0'},
        'Log::Log4perl' => {version=>'0'},
        'Log::Log4perl::Tiny' => {version=>'0'},
        'Log::Dispatchouli' => {version=>'0'},
        'Mojo::Log' => {version=>'0'},
    },
    code_startup => 1,
    participants => [
        # a benchmark for Log::ger: strict/warnings
        {code_template=>'use strict;'},
        {code_template=>'use warnings;'},
        {code_template=>'use strict; use warnings;'},

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

        {code_template=>'use Log::Dispatch;'},
        {code_template=>'use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Null", min_level=>"warn"] ])', tags=>['output']},

        {code_template=>'use Log::Dispatchouli;'},

        {code_template=>'use Log::ger::Output::Screen;', tags=>['output']},
        {code_template=>'use Log::ger::Output::Composite;', tags=>['output']},

        {code_template=>'use Mojo::Log;'},
        {code_template=>'use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")'},

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

This document describes version 0.016 of Bencher::Scenario::LogGer::Overhead (from Perl distribution Bencher-Scenarios-LogGer), released on 2020-01-13.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.707

L<Log::Contextual> 0.008001

L<Log::Dispatch> 2.68

L<Log::Dispatch::Null> 2.68

L<Log::Dispatchouli> 2.019

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.028

L<Log::ger::App> 0.013

L<Log::ger::Layout::Pattern> 0.004

L<Log::ger::Output> 0.028

L<Mojo::Log>

=head1 BENCHMARK PARTICIPANTS

=over

=item * use strict; (perl_code)

Code template:

 use strict;



=item * use warnings; (perl_code)

Code template:

 use warnings;



=item * use strict; use warnings; (perl_code)

Code template:

 use strict; use warnings;



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



=item * use Log::Dispatch; (perl_code)

Code template:

 use Log::Dispatch;



=item * use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu (perl_code) [output]

Code template:

 use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Null", min_level=>"warn"] ])



=item * use Log::Dispatchouli; (perl_code)

Code template:

 use Log::Dispatchouli;



=item * use Log::ger::Output::Screen; (perl_code) [output]

Code template:

 use Log::ger::Output::Screen;



=item * use Log::ger::Output::Composite; (perl_code) [output]

Code template:

 use Log::ger::Output::Composite;



=item * use Mojo::Log; (perl_code)

Code template:

 use Mojo::Log;



=item * use Mojo::Log; my $log=Mojo::Log->new(level=>"warn") (perl_code)

Code template:

 use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m LogGer::Overhead >>):

 #table1#
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+---------+---------+
 | participant                                                      | time (ms) | code_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+---------+---------+
 | use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")             |    103    | 96.1               |                 0.00% |              1379.96% | 7.4e-05 |      21 |
 | use Mojo::Log;                                                   |    103    | 96.1               |                 0.04% |              1379.31% | 8.2e-05 |      20 |
 | use Log::Dispatchouli;                                           |     79.3  | 72.4               |                29.65% |              1041.53% | 3.5e-05 |      23 |
 | use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu |     76.2  | 69.3               |                34.99% |               996.38% | 1.7e-05 |      21 |
 | use Log::Dispatch;                                               |     71.6  | 64.7               |                43.62% |               930.47% | 5.8e-05 |      20 |
 | use Log::Contextual qw(:log);                                    |     68.1  | 61.2               |                50.87% |               880.98% | 4.9e-05 |      20 |
 | use Log::Log4perl;                                               |     34    | 27.1               |               199.94% |               393.41% | 4.2e-05 |      20 |
 | use Log::ger::App; use Log::ger;                                 |     26.4  | 19.5               |               289.97% |               279.50% |   2e-05 |      20 |
 | use Log::ger::App;                                               |     22.7  | 15.8               |               352.31% |               227.20% | 1.1e-05 |      21 |
 | use Log::Log4perl::Tiny;                                         |     18.8  | 11.9               |               447.31% |               170.41% | 1.7e-05 |      20 |
 | use Log::ger::Like::Log4perl;                                    |     17    | 10.1               |               505.97% |               144.23% |   1e-05 |      20 |
 | use Log::Any q($log);                                            |     14.1  |  7.2               |               631.39% |               102.35% |   6e-06 |      20 |
 | use Log::Any;                                                    |     13.6  |  6.7               |               655.33% |                95.93% | 5.3e-06 |      24 |
 | use Log::ger::Output::Composite;                                 |     12.5  |  5.6               |               724.85% |                79.42% | 3.1e-06 |      20 |
 | use Log::ger::Output::Screen;                                    |     11.8  |  4.9               |               767.86% |                70.53% | 2.9e-06 |      20 |
 | use Log::ger::Plugin::OptAway; use Log::ger;                     |      9.58 |  2.68              |               972.95% |                37.93% | 2.5e-06 |      20 |
 | use strict; use warnings;                                        |      8.76 |  1.86              |              1073.05% |                26.16% | 5.4e-06 |      20 |
 | use warnings;                                                    |      8.53 |  1.63              |              1104.69% |                22.85% | 4.2e-06 |      21 |
 | use Log::ger::Like::LogAny;                                      |      7.78 |  0.88              |              1221.30% |                12.01% | 4.7e-06 |      20 |
 | use Log::ger; Log::ger->get_logger;                              |      7.64 |  0.739999999999999 |              1245.54% |                 9.99% | 5.9e-06 |      21 |
 | use Log::ger;                                                    |      7.59 |  0.69              |              1255.32% |                 9.20% | 2.7e-06 |      20 |
 | use Log::ger ();                                                 |      7.54 |  0.64              |              1262.83% |                 8.59% | 5.1e-06 |      20 |
 | use strict;                                                      |      7.33 |  0.43              |              1303.30% |                 5.46% | 6.7e-06 |      20 |
 | perl -e1 (baseline)                                              |      6.9  |  0                 |              1379.96% |                 0.00% | 2.3e-05 |      21 |
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+---------+---------+


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

This software is copyright (c) 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
